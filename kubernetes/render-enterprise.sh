#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="${1:-}"
api_image="${CLASSIC_ENTERPRISE_API_IMAGE:-}"
ui_image="${CLASSIC_ENTERPRISE_UI_IMAGE:-}"
namespace="${CLASSIC_ENTERPRISE_NAMESPACE:-classic-enterprise}"
flink_namespace="${CLASSIC_ENTERPRISE_FLINK_NAMESPACE:-classic-enterprise-flink}"
pull_secret="${CLASSIC_ENTERPRISE_API_IMAGE_PULL_SECRET:-}"
ui_pull_secret="${CLASSIC_ENTERPRISE_UI_IMAGE_PULL_SECRET:-$pull_secret}"
ingress_host="${CLASSIC_ENTERPRISE_INGRESS_HOST:-}"
ingress_tls_secret="${CLASSIC_ENTERPRISE_INGRESS_TLS_SECRET:-}"
ingress_namespace="${CLASSIC_ENTERPRISE_INGRESS_NAMESPACE:-}"
core_revision="${CLASSIC_ENTERPRISE_CORE_REVISION:-}"
enterprise_revision="${CLASSIC_ENTERPRISE_ENTERPRISE_REVISION:-}"
deployment_revision="${CLASSIC_ENTERPRISE_DEPLOYMENT_REVISION:-}"
release_inputs="${CLASSIC_ENTERPRISE_RELEASE_INPUTS:-}"

fail() {
  echo "error: $*" >&2
  exit 1
}

[[ -n "$OUTPUT" && "$OUTPUT" != -* ]] || {
  echo "usage: CLASSIC_ENTERPRISE_API_IMAGE=... [CLASSIC_ENTERPRISE_UI_IMAGE=...] CLASSIC_ENTERPRISE_CORE_REVISION=... CLASSIC_ENTERPRISE_ENTERPRISE_REVISION=... CLASSIC_ENTERPRISE_DEPLOYMENT_REVISION=... CLASSIC_ENTERPRISE_RELEASE_INPUTS=... [CLASSIC_ENTERPRISE_INGRESS_HOST=... CLASSIC_ENTERPRISE_INGRESS_TLS_SECRET=... CLASSIC_ENTERPRISE_INGRESS_NAMESPACE=...] $0 OUTPUT.yaml" >&2
  exit 2
}
[[ ! -e "$OUTPUT" && ! -L "$OUTPUT" ]] || fail "output path already exists: $OUTPUT"
validate_image() {
  local name="$1" value="$2"
  [[ "$value" =~ ^.+@sha256:[0-9a-f]{64}$ ]] || fail "$name must be an immutable RepoDigest"
  [[ "$value" != registry.example.com/* ]] || fail "example image registry is not allowed"
  [[ "$value" != *@sha256:0000000000000000000000000000000000000000000000000000000000000000 ]] || {
    fail "zero image digest is not allowed"
  }
}

validate_image CLASSIC_ENTERPRISE_API_IMAGE "$api_image"

validate_revision() {
  local name="$1" value="$2"
  [[ "$value" =~ ^[0-9a-f]{7,64}$ ]] || fail "$name must be a lowercase hexadecimal Git revision"
}

validate_digest() {
  local name="$1" value="$2"
  [[ "$value" =~ ^[0-9a-f]{64}$ ]] || fail "$name must be a 64-character lowercase SHA-256 digest"
}

validate_revision CLASSIC_ENTERPRISE_CORE_REVISION "$core_revision"
validate_revision CLASSIC_ENTERPRISE_ENTERPRISE_REVISION "$enterprise_revision"
validate_revision CLASSIC_ENTERPRISE_DEPLOYMENT_REVISION "$deployment_revision"
validate_digest CLASSIC_ENTERPRISE_RELEASE_INPUTS "$release_inputs"
release_inputs_label="${release_inputs:0:63}"
[[ ${#release_inputs_label} -eq 63 ]] || {
  fail "CLASSIC_ENTERPRISE_RELEASE_INPUTS label projection must be exactly 63 characters"
}

validate_dns_name() {
  local name="$1" value="$2"
  [[ "$value" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] || fail "$name must be a DNS label"
  [[ ${#value} -le 63 ]] || fail "$name is too long"
}

validate_secret_name() {
  local name="$1" value="$2"
  local pattern='^([a-z0-9]([-a-z0-9]*[a-z0-9])?)(\.([a-z0-9]([-a-z0-9]*[a-z0-9])?))*$'
  [[ ${#value} -le 253 && "$value" =~ $pattern ]] || fail "$name must be a DNS subdomain"
}

validate_hostname() {
  local name="$1" value="$2"
  [[ ${#value} -le 253 && "$value" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*$ ]] \
    || fail "$name must be a lowercase DNS hostname"
}

validate_dns_name CLASSIC_ENTERPRISE_NAMESPACE "$namespace"
validate_dns_name CLASSIC_ENTERPRISE_FLINK_NAMESPACE "$flink_namespace"
[[ "$namespace" != "$flink_namespace" ]] || {
  fail "Enterprise API and Flink namespaces must be distinct"
}
for reserved_namespace in mds-app mds-flink data-infra mds-m2-acceptance; do
  [[ "$namespace" != "$reserved_namespace" ]] || {
    fail "Enterprise namespace must be isolated from reserved namespace '$reserved_namespace'"
  }
  [[ "$flink_namespace" != "$reserved_namespace" ]] || {
    fail "Enterprise Flink namespace must be isolated from reserved namespace '$reserved_namespace'"
  }
done
if [[ -n "$ingress_host" || -n "$ingress_tls_secret" || -n "$ingress_namespace" ]]; then
  [[ -n "$ingress_host" && -n "$ingress_tls_secret" && -n "$ingress_namespace" ]] || {
    fail "CLASSIC_ENTERPRISE_INGRESS_HOST, CLASSIC_ENTERPRISE_INGRESS_TLS_SECRET, and CLASSIC_ENTERPRISE_INGRESS_NAMESPACE must be provided together"
  }
  validate_hostname CLASSIC_ENTERPRISE_INGRESS_HOST "$ingress_host"
  validate_secret_name CLASSIC_ENTERPRISE_INGRESS_TLS_SECRET "$ingress_tls_secret"
  validate_dns_name CLASSIC_ENTERPRISE_INGRESS_NAMESPACE "$ingress_namespace"
  [[ -n "$ui_image" ]] || fail "CLASSIC_ENTERPRISE_UI_IMAGE is required when an Enterprise Ingress is configured"
  CLASSIC_ENTERPRISE_API_INGRESS_POLICY_BLOCK="$(cat <<EOF
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ${ingress_namespace}
EOF
)"
  CLASSIC_ENTERPRISE_INGRESS_BLOCK="$(cat <<EOF
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: classic-enterprise-api
  namespace: ${namespace}
  labels:
    app.kubernetes.io/name: classic-enterprise-api
    app.kubernetes.io/part-of: coomia-classic-enterprise
    coomia.com/edition: enterprise
    coomia.com/isolation: dedicated
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
spec:
  ingressClassName: nginx
  tls:
    - hosts: [${ingress_host}]
      secretName: ${ingress_tls_secret}
  rules:
    - host: ${ingress_host}
      http:
        paths:
          - path: /api/copilotkit
            pathType: Prefix
            backend:
              service:
                name: classic-enterprise-api
                port:
                  name: http
          - path: /
            pathType: Prefix
            backend:
              service:
                name: classic-enterprise-ui
                port:
                  name: http
EOF
)"
else
  CLASSIC_ENTERPRISE_INGRESS_BLOCK=""
  CLASSIC_ENTERPRISE_API_INGRESS_POLICY_BLOCK=""
fi
if [[ -n "$ui_image" ]]; then
  validate_image CLASSIC_ENTERPRISE_UI_IMAGE "$ui_image"
  if [[ -n "$ui_pull_secret" ]]; then
    validate_secret_name CLASSIC_ENTERPRISE_UI_IMAGE_PULL_SECRET "$ui_pull_secret"
    CLASSIC_ENTERPRISE_UI_IMAGE_PULL_SECRETS_BLOCK="$(printf '      imagePullSecrets:\n        - name: %s' "$ui_pull_secret")"
  else
    CLASSIC_ENTERPRISE_UI_IMAGE_PULL_SECRETS_BLOCK=""
  fi
else
  CLASSIC_ENTERPRISE_UI_IMAGE_PULL_SECRETS_BLOCK=""
fi
if [[ -n "$pull_secret" ]]; then
  validate_secret_name CLASSIC_ENTERPRISE_API_IMAGE_PULL_SECRET "$pull_secret"
  CLASSIC_ENTERPRISE_API_IMAGE_PULL_SECRETS_BLOCK="$(printf '      imagePullSecrets:\n        - name: %s' "$pull_secret")"
else
  CLASSIC_ENTERPRISE_API_IMAGE_PULL_SECRETS_BLOCK=""
fi

export CLASSIC_ENTERPRISE_API_IMAGE
export CLASSIC_ENTERPRISE_UI_IMAGE="$ui_image"
export CLASSIC_ENTERPRISE_NAMESPACE="$namespace"
export CLASSIC_ENTERPRISE_FLINK_NAMESPACE="$flink_namespace"
export CLASSIC_ENTERPRISE_API_IMAGE_PULL_SECRETS_BLOCK
export CLASSIC_ENTERPRISE_API_INGRESS_POLICY_BLOCK
export CLASSIC_ENTERPRISE_UI_INGRESS_POLICY_BLOCK="$CLASSIC_ENTERPRISE_API_INGRESS_POLICY_BLOCK"
export CLASSIC_ENTERPRISE_INGRESS_BLOCK
export CLASSIC_ENTERPRISE_UI_IMAGE_PULL_SECRETS_BLOCK
export CLASSIC_ENTERPRISE_CORE_REVISION="$core_revision"
export CLASSIC_ENTERPRISE_ENTERPRISE_REVISION="$enterprise_revision"
export CLASSIC_ENTERPRISE_DEPLOYMENT_REVISION="$deployment_revision"
export CLASSIC_ENTERPRISE_RELEASE_INPUTS="$release_inputs"
export CLASSIC_ENTERPRISE_RELEASE_INPUTS_LABEL="$release_inputs_label"

mkdir -p -- "$(dirname -- "$OUTPUT")"
temporary="${OUTPUT}.tmp.$$"
[[ ! -e "$temporary" && ! -L "$temporary" ]] || fail "temporary output path already exists: $temporary"
trap 'rm -f -- "$temporary"' EXIT
envsubst '${CLASSIC_ENTERPRISE_API_IMAGE} ${CLASSIC_ENTERPRISE_NAMESPACE} ${CLASSIC_ENTERPRISE_FLINK_NAMESPACE} ${CLASSIC_ENTERPRISE_API_IMAGE_PULL_SECRETS_BLOCK} ${CLASSIC_ENTERPRISE_API_INGRESS_POLICY_BLOCK} ${CLASSIC_ENTERPRISE_INGRESS_BLOCK} ${CLASSIC_ENTERPRISE_CORE_REVISION} ${CLASSIC_ENTERPRISE_ENTERPRISE_REVISION} ${CLASSIC_ENTERPRISE_DEPLOYMENT_REVISION} ${CLASSIC_ENTERPRISE_RELEASE_INPUTS} ${CLASSIC_ENTERPRISE_RELEASE_INPUTS_LABEL}' \
  < "$SCRIPT_DIR/20-classic-enterprise-api.yaml" > "$temporary"
printf '\n---\n' >> "$temporary"
envsubst '${CLASSIC_ENTERPRISE_FLINK_NAMESPACE} ${CLASSIC_ENTERPRISE_CORE_REVISION} ${CLASSIC_ENTERPRISE_ENTERPRISE_REVISION} ${CLASSIC_ENTERPRISE_DEPLOYMENT_REVISION} ${CLASSIC_ENTERPRISE_RELEASE_INPUTS} ${CLASSIC_ENTERPRISE_RELEASE_INPUTS_LABEL}' \
  < "$SCRIPT_DIR/21-classic-enterprise-flink-namespace.yaml" >> "$temporary"

if [[ -n "$ui_image" ]]; then
  printf '\n---\n' >> "$temporary"
  envsubst '${CLASSIC_ENTERPRISE_UI_IMAGE} ${CLASSIC_ENTERPRISE_NAMESPACE} ${CLASSIC_ENTERPRISE_UI_IMAGE_PULL_SECRETS_BLOCK} ${CLASSIC_ENTERPRISE_UI_INGRESS_POLICY_BLOCK} ${CLASSIC_ENTERPRISE_CORE_REVISION} ${CLASSIC_ENTERPRISE_ENTERPRISE_REVISION} ${CLASSIC_ENTERPRISE_DEPLOYMENT_REVISION} ${CLASSIC_ENTERPRISE_RELEASE_INPUTS} ${CLASSIC_ENTERPRISE_RELEASE_INPUTS_LABEL}' \
    < "$SCRIPT_DIR/22-classic-enterprise-ui.yaml" >> "$temporary"
fi

if grep -Fq '${' "$temporary"; then
  fail "rendered Enterprise manifest contains unresolved template variables"
fi

grep -Fq "name: classic-enterprise-api" "$temporary" || fail "Enterprise workload identity is missing"
grep -Fq "name: classic-enterprise-license" "$temporary" || fail "Enterprise License PVC is missing"
grep -Fq "coomia.com/edition: enterprise" "$temporary" || fail "Enterprise selector boundary is missing"
grep -Fq "kind: NetworkPolicy" "$temporary" || fail "Enterprise ingress isolation policy is missing"
grep -Fq "coomia.com/role: classic-enterprise-flink" "$temporary" || fail "Enterprise Flink namespace is missing"
grep -Fq "name: $flink_namespace" "$temporary" || fail "Enterprise Flink namespace identity is missing"
grep -Fq "name: classic-enterprise-api-ingress" "$temporary" || fail "Enterprise ingress policy identity is missing"
grep -Fq "runAsNonRoot: true" "$temporary" || fail "Enterprise Pod must run as non-root"
grep -Fq "type: RuntimeDefault" "$temporary" || fail "Enterprise Pod must use the RuntimeDefault seccomp profile"
grep -Fq "allowPrivilegeEscalation: false" "$temporary" || fail "Enterprise container privilege escalation must be disabled"
grep -Fq 'drop: ["ALL"]' "$temporary" || fail "Enterprise container capabilities must be dropped"
grep -Fq "coomia.com/release-inputs: \"$release_inputs\"" "$temporary" || fail "full release-inputs annotation is missing"
grep -Fq "coomia.com/release-inputs: \"$release_inputs_label\"" "$temporary" || fail "63-character release-inputs label is missing"
grep -Fq "name: platform-api" "$temporary" && fail "Core workload identity leaked into Enterprise manifest"
if [[ -n "$ui_image" ]]; then
  grep -Fq "name: classic-enterprise-ui" "$temporary" || fail "Enterprise UI workload identity is missing"
  grep -Fq "port: 3000" "$temporary" || fail "Enterprise UI service port is missing"
  grep -Fq "classic-enterprise-ui-ingress" "$temporary" || fail "Enterprise UI ingress policy is missing"
fi
if [[ -n "$ingress_host" ]]; then
  grep -Fq "kind: Ingress" "$temporary" || fail "configured Enterprise host has no Ingress"
  grep -Fq "host: $ingress_host" "$temporary" || fail "configured Enterprise host is missing"
  grep -Fq "secretName: $ingress_tls_secret" "$temporary" || fail "configured Enterprise TLS secret is missing"
  grep -Fq "path: /api/copilotkit" "$temporary" || fail "copilotkit route is missing"
  grep -Fq "name: classic-enterprise-ui" "$temporary" || fail "Enterprise root route has no UI service"
fi
if command -v kubectl >/dev/null 2>&1 && [[ "${VALIDATE_KUBECTL:-0}" == "1" ]]; then
  kubectl apply --dry-run=client -f "$temporary" >/dev/null
fi
mv -- "$temporary" "$OUTPUT"
trap - EXIT
printf 'Rendered isolated Enterprise manifest: %s\n' "$OUTPUT"
