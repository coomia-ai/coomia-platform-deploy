#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export KUBECONFIG="${KUBECONFIG:-/etc/kubernetes/admin.conf}"
: "${K8S_PROBE_IMAGE:?set K8S_PROBE_IMAGE to an approved immutable RepoDigest}"
[[ "$K8S_PROBE_IMAGE" =~ ^[^[:space:]]+@sha256:[0-9a-f]{64}$ ]] || {
  echo "error: K8S_PROBE_IMAGE must be an immutable RepoDigest" >&2
  exit 1
}

echo "==> applying fail-closed Flink namespace isolation"
# RoleBinding.roleRef is immutable. Reconcile RBAC first so upgrades from the
# legacy ClusterRole/edit binding can recreate it before server-side apply.
kubectl auth reconcile \
  --remove-extra-permissions \
  --remove-extra-subjects \
  -f "$SCRIPT_DIR/mds-flink-namespace.yaml"
kubectl apply --server-side -f "$SCRIPT_DIR/mds-flink-namespace.yaml"

for policy in \
  mds-flink-job-secret-isolation \
  mds-flink-job-pod-delete-isolation \
  mds-flink-job-resource-isolation \
  mds-flink-rolebinding-isolation; do
  kubectl get validatingadmissionpolicy "$policy" >/dev/null
  kubectl get validatingadmissionpolicybinding "$policy" >/dev/null
done

# Prove that the API server, rather than only the local YAML parser, rejects a
# privileged workload submitted as a Flink job identity. A successful dry-run
# means the cluster is unsafe and must stop the release.
set +e
PROBE_OUTPUT=$(kubectl --as=system:serviceaccount:mds-flink:mds-bootstrap-probe \
  -n mds-flink create --dry-run=server -f - 2>&1 <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: mds-bootstrap-probe
  labels:
    app: mds-bootstrap-probe
spec:
  serviceAccountName: mds-bootstrap-probe
  containers:
    - name: probe
      image: ${K8S_PROBE_IMAGE}
      securityContext:
        privileged: true
      command: ["sh", "-c", "true"]
EOF
)
PROBE_STATUS=$?
set -e

if [ "$PROBE_STATUS" -eq 0 ]; then
  echo "error: Flink privileged-Pod admission probe was unexpectedly accepted" >&2
  exit 1
fi

if ! grep -Eqi 'violates PodSecurity|restricted.*privileged|privileged.*forbidden' <<<"$PROBE_OUTPUT"; then
  echo "error: Flink admission probe failed for an unexpected reason:" >&2
  printf '%s\n' "$PROBE_OUTPUT" >&2
  exit 1
fi

echo "==> Flink admission isolation verified"
