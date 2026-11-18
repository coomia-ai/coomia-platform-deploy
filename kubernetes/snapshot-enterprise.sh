#!/usr/bin/env bash
set -euo pipefail
umask 077

namespace="${CLASSIC_ENTERPRISE_NAMESPACE:-classic-enterprise}"
flink_namespace="${CLASSIC_ENTERPRISE_FLINK_NAMESPACE:-classic-enterprise-flink}"
output="${1:-}"

fail() {
  echo "error: $*" >&2
  exit 1
}

[[ -n "$output" && "$output" != -* ]] || {
  echo "usage: CLASSIC_ENTERPRISE_NAMESPACE=classic-enterprise $0 OUTPUT_DIRECTORY" >&2
  exit 2
}
command -v kubectl >/dev/null 2>&1 || fail "kubectl is required"

validate_namespace() {
  local value="$1"
  [[ "$value" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] || fail "namespace must be a DNS label"
  [[ ${#value} -le 63 ]] || fail "namespace is too long"
  case "$value" in
    mds-app|mds-flink|data-infra|mds-m2-acceptance)
      fail "Enterprise snapshot cannot target reserved namespace '$value'"
      ;;
  esac
}

validate_namespace "$namespace"
validate_namespace "$flink_namespace"
[[ "$namespace" != "$flink_namespace" ]] || fail "Enterprise API and Flink namespaces must be distinct"
[[ ! -e "$output" && ! -L "$output" ]] || fail "output path already exists: $output"

temporary="${output}.tmp.$$"
[[ ! -e "$temporary" && ! -L "$temporary" ]] || fail "temporary snapshot path already exists: $temporary"
trap 'rm -rf -- "$temporary"' EXIT
mkdir -p -- "$temporary"

kubectl get namespace "$flink_namespace" -o yaml \
  > "$temporary/enterprise-flink-namespace.before.yaml"
kubectl get namespace "$namespace" -o yaml \
  > "$temporary/enterprise-api-namespace.before.yaml"

kubectl -n "$namespace" get deployment classic-enterprise-api -o yaml \
  > "$temporary/enterprise-deployment.before.yaml"
kubectl -n "$namespace" get deployment classic-enterprise-ui --ignore-not-found -o yaml \
  > "$temporary/enterprise-ui-deployment.before.yaml"
kubectl -n "$namespace" get service classic-enterprise-api -o yaml \
  > "$temporary/enterprise-service.before.yaml"
kubectl -n "$namespace" get service classic-enterprise-ui --ignore-not-found -o yaml \
  > "$temporary/enterprise-ui-service.before.yaml"
kubectl -n "$namespace" get configmap classic-enterprise-api-config -o yaml \
  > "$temporary/enterprise-config.before.yaml"
kubectl -n "$namespace" get pvc classic-enterprise-license -o yaml \
  > "$temporary/enterprise-license-pvc.before.yaml"
kubectl -n "$namespace" get serviceaccount classic-enterprise-api -o yaml \
  > "$temporary/enterprise-serviceaccount.before.yaml"
kubectl -n "$namespace" get networkpolicy -o yaml \
  > "$temporary/enterprise-networkpolicies.before.yaml"
kubectl -n "$namespace" get ingress classic-enterprise-api --ignore-not-found -o yaml \
  > "$temporary/enterprise-ingress.before.yaml"

# Secret data is intentionally excluded; this records only identity metadata.
kubectl -n "$namespace" get secret classic-enterprise-api-secret \
  -o 'jsonpath={.metadata.name}{"\t"}{.metadata.uid}{"\t"}{.metadata.resourceVersion}{"\n"}' \
  > "$temporary/enterprise-api-secret.metadata.before.txt"
kubectl -n "$namespace" get deployment classic-enterprise-api \
  -o 'jsonpath={.spec.template.spec.containers[?(@.name=="api")].image}{"\n"}' \
  > "$temporary/enterprise-api-image.before.txt"
kubectl -n "$namespace" get deployment classic-enterprise-ui --ignore-not-found \
  -o 'jsonpath={.spec.template.spec.containers[?(@.name=="ui")].image}{"\n"}' \
  > "$temporary/enterprise-ui-image.before.txt"
kubectl -n "$namespace" rollout history deployment/classic-enterprise-api \
  > "$temporary/enterprise-rollout-history.before.txt"

cat > "$temporary/README.txt" <<EOF
Enterprise metadata snapshot
namespace: $namespace
flink namespace: $flink_namespace
secret data: excluded
database/object/Kafka/License data: not backed up by this snapshot
EOF

mv -- "$temporary" "$output"
trap - EXIT
printf 'Captured Enterprise metadata snapshot: %s\n' "$output"
