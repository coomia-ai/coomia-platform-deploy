#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export KUBECONFIG="${KUBECONFIG:-/etc/kubernetes/admin.conf}"

release_value() {
  sed -n "s/^$1=//p" "$REPO_ROOT/RELEASE_STATUS"
}

if [[ "$(release_value RELEASE_STATUS)" != "GO" ]] \
  || [[ "$(release_value KUBERNETES_STATUS)" != "GO" ]]; then
  echo "error: the Kubernetes package is not approved as a complete customer release; see RELEASE_STATUS" >&2
  exit 1
fi

: "${FLINK_K8S_IMAGE:?set FLINK_K8S_IMAGE to the licensed image RepoDigest}"
: "${PLATFORM_API_IMAGE:?set PLATFORM_API_IMAGE to the licensed API image RepoDigest}"
: "${K8S_PROBE_IMAGE:?set K8S_PROBE_IMAGE to an approved immutable RepoDigest}"
: "${FLINK_UNIFIED_ARTIFACT_SHA256:?set FLINK_UNIFIED_ARTIFACT_SHA256 to the released Flink JAR digest}"
FLINK_K8S_IMAGE_PULL_SECRET="${FLINK_K8S_IMAGE_PULL_SECRET:-}"
PLATFORM_API_IMAGE_PULL_SECRET="${PLATFORM_API_IMAGE_PULL_SECRET:-}"

validate_image_digest() {
  local name="$1"
  local image="$2"
  if [[ ! "$image" =~ ^.+@sha256:[0-9a-f]{64}$ ]] \
    || [[ "$image" == registry.example.com/* ]] \
    || [[ "$image" == *@sha256:0000000000000000000000000000000000000000000000000000000000000000 ]]; then
    echo "error: $name must be a real immutable RepoDigest, not an example or zero digest" >&2
    exit 1
  fi
}

validate_image_digest "FLINK_K8S_IMAGE" "$FLINK_K8S_IMAGE"
validate_image_digest "PLATFORM_API_IMAGE" "$PLATFORM_API_IMAGE"
validate_image_digest "K8S_PROBE_IMAGE" "$K8S_PROBE_IMAGE"
[[ "$FLINK_UNIFIED_ARTIFACT_SHA256" =~ ^[0-9a-f]{64}$ ]] || {
  echo "error: FLINK_UNIFIED_ARTIFACT_SHA256 must be a 64-character lowercase SHA256" >&2
  exit 1
}

validate_secret_name() {
  local name="$1"
  local value="$2"
  local pattern='^([a-z0-9]([-a-z0-9]*[a-z0-9])?)(\.([a-z0-9]([-a-z0-9]*[a-z0-9])?))*$'
  [[ ${#value} -le 253 && "$value" =~ $pattern ]] || {
    echo "error: $name must be a valid Kubernetes DNS subdomain name" >&2
    exit 1
  }
}
if [[ -n "$FLINK_K8S_IMAGE_PULL_SECRET" ]]; then
  validate_secret_name "FLINK_K8S_IMAGE_PULL_SECRET" "$FLINK_K8S_IMAGE_PULL_SECRET"
fi
if [[ -n "$PLATFORM_API_IMAGE_PULL_SECRET" ]]; then
  validate_secret_name "PLATFORM_API_IMAGE_PULL_SECRET" "$PLATFORM_API_IMAGE_PULL_SECRET"
fi

command -v envsubst >/dev/null || {
  echo "error: envsubst is required to render the customer manifest" >&2
  exit 1
}

# Establish and verify the admission boundary before inspecting resources in
# mds-flink.  This also creates the namespace on a fresh cluster.
bash "$SCRIPT_DIR/apply-flink-isolation.sh"

kubectl get namespace mds-app >/dev/null || {
  echo "error: namespace mds-app is missing; install the app namespace/infra first" >&2
  exit 1
}
if [[ -n "$FLINK_K8S_IMAGE_PULL_SECRET" ]]; then
  kubectl -n mds-flink get secret "$FLINK_K8S_IMAGE_PULL_SECRET" >/dev/null || {
    echo "error: Flink image pull Secret '$FLINK_K8S_IMAGE_PULL_SECRET' is missing from mds-flink" >&2
    exit 1
  }
fi
if [[ -n "$PLATFORM_API_IMAGE_PULL_SECRET" ]]; then
  kubectl -n mds-app get secret "$PLATFORM_API_IMAGE_PULL_SECRET" >/dev/null || {
    echo "error: API image pull Secret '$PLATFORM_API_IMAGE_PULL_SECRET' is missing from mds-app" >&2
    exit 1
  }
fi
kubectl -n mds-app get secret platform-api-secret >/dev/null || {
  echo "error: required application Secret 'platform-api-secret' is missing from mds-app" >&2
  exit 1
}
for key in DATABASE_URL MINIO_ACCESS_KEY MINIO_SECRET_KEY S3_ACCESS_KEY S3_SECRET_KEY \
  DORIS_PASSWORD REDIS_PASSWORD TUGRAPH_PASSWORD JWT_SECRET DELIVERY_REPORT_HMAC_SECRET; do
  value="$(kubectl -n mds-app get secret platform-api-secret -o "jsonpath={.data.${key}}")"
  if [[ -z "$value" ]]; then
    echo "error: platform-api-secret is missing required key $key" >&2
    exit 1
  fi
done
jwt_encoded="$(kubectl -n mds-app get secret platform-api-secret -o 'jsonpath={.data.JWT_SECRET}')"
jwt_secret="$(printf '%s' "$jwt_encoded" | base64 --decode)"
if [[ ${#jwt_secret} -lt 32 ]] \
  || [[ "$jwt_secret" == "change-me-in-production" ]] \
  || [[ "$jwt_secret" == "e2e-fake-jwt-for-ui-testing" ]]; then
  echo "error: platform-api-secret JWT_SECRET must be unique, non-default, and at least 32 characters" >&2
  exit 1
fi
report_encoded="$(kubectl -n mds-app get secret platform-api-secret -o 'jsonpath={.data.DELIVERY_REPORT_HMAC_SECRET}')"
delivery_report_secret="$(printf '%s' "$report_encoded" | base64 --decode)"
if [[ ${#delivery_report_secret} -lt 32 ]] || [[ "$delivery_report_secret" == "$jwt_secret" ]]; then
  echo "error: platform-api-secret DELIVERY_REPORT_HMAC_SECRET must be distinct from JWT_SECRET and at least 32 characters" >&2
  exit 1
fi

RENDERED_MANIFEST="$(mktemp)"
trap 'rm -f -- "$RENDERED_MANIFEST"' EXIT
PLATFORM_API_IMAGE_PULL_SECRETS_BLOCK=""
if [[ -n "$PLATFORM_API_IMAGE_PULL_SECRET" ]]; then
  PLATFORM_API_IMAGE_PULL_SECRETS_BLOCK="$(printf '      imagePullSecrets:\n        - name: %s' "$PLATFORM_API_IMAGE_PULL_SECRET")"
fi
export FLINK_K8S_IMAGE_PULL_SECRET PLATFORM_API_IMAGE_PULL_SECRETS_BLOCK
envsubst '${FLINK_K8S_IMAGE} ${FLINK_K8S_IMAGE_PULL_SECRET} ${PLATFORM_API_IMAGE} ${PLATFORM_API_IMAGE_PULL_SECRETS_BLOCK} ${FLINK_UNIFIED_ARTIFACT_SHA256}' \
  < "$SCRIPT_DIR/10-platform-api.yaml" > "$RENDERED_MANIFEST"

kubectl apply -f "$RENDERED_MANIFEST"
