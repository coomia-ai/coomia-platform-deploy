#!/usr/bin/env bash
set -euo pipefail

# Roll back the dedicated Enterprise UI without touching the API or Flink
# workloads. The target must be an immutable image reference so an operator
# can prove which release was restored.
namespace="${CLASSIC_ENTERPRISE_NAMESPACE:-classic-enterprise}"
revision="${1:-}"

fail() {
  echo "error: $*" >&2
  exit 1
}

[[ -n "$revision" && "$revision" != -* ]] || {
  echo "usage: CONFIRM_ENTERPRISE_ROLLBACK=YES CLASSIC_ENTERPRISE_ROLLBACK_UI_IMAGE=repo@sha256:<digest> CLASSIC_ENTERPRISE_ROLLBACK_CORE_REVISION=<rev> CLASSIC_ENTERPRISE_ROLLBACK_ENTERPRISE_REVISION=<rev> CLASSIC_ENTERPRISE_ROLLBACK_RELEASE_INPUTS=<sha256> $0 REVISION" >&2
  exit 2
}
[[ "$revision" =~ ^[1-9][0-9]*$ ]] || fail "revision must be a positive rollout revision"
[[ "${CONFIRM_ENTERPRISE_ROLLBACK:-}" == YES ]] || {
  fail "set CONFIRM_ENTERPRISE_ROLLBACK=YES after the approved rollback impact review"
}
command -v kubectl >/dev/null 2>&1 || fail "kubectl is required"

validate_namespace() {
  local value="$1"
  [[ "$value" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] || fail "namespace must be a DNS label"
  [[ ${#value} -le 63 ]] || fail "namespace is too long"
  case "$value" in
    mds-app|mds-flink|data-infra|mds-m2-acceptance)
      fail "Enterprise rollback cannot target reserved namespace '$value'"
      ;;
  esac
}

validate_digest() {
  local name="$1" value="$2"
  [[ "$value" =~ ^.+@sha256:[0-9a-f]{64}$ ]] || fail "$name must be an immutable RepoDigest"
  [[ "$value" != *@sha256:0000000000000000000000000000000000000000000000000000000000000000 ]] || fail "$name cannot use a zero digest"
}

validate_revision() {
  local name="$1" value="$2"
  [[ "$value" =~ ^[0-9a-f]{7,64}$ ]] || fail "$name must be lowercase hexadecimal"
}

validate_namespace "$namespace"
rollback_ui_image="${CLASSIC_ENTERPRISE_ROLLBACK_UI_IMAGE:-}"
rollback_core="${CLASSIC_ENTERPRISE_ROLLBACK_CORE_REVISION:-}"
rollback_enterprise="${CLASSIC_ENTERPRISE_ROLLBACK_ENTERPRISE_REVISION:-}"
rollback_inputs="${CLASSIC_ENTERPRISE_ROLLBACK_RELEASE_INPUTS:-}"
[[ -n "$rollback_ui_image" ]] || fail "CLASSIC_ENTERPRISE_ROLLBACK_UI_IMAGE is required"
[[ -n "$rollback_core" ]] || fail "CLASSIC_ENTERPRISE_ROLLBACK_CORE_REVISION is required"
[[ -n "$rollback_enterprise" ]] || fail "CLASSIC_ENTERPRISE_ROLLBACK_ENTERPRISE_REVISION is required"
[[ "$rollback_inputs" =~ ^[0-9a-f]{64}$ ]] || fail "CLASSIC_ENTERPRISE_ROLLBACK_RELEASE_INPUTS must be a SHA-256"
validate_digest CLASSIC_ENTERPRISE_ROLLBACK_UI_IMAGE "$rollback_ui_image"
validate_revision CLASSIC_ENTERPRISE_ROLLBACK_CORE_REVISION "$rollback_core"
validate_revision CLASSIC_ENTERPRISE_ROLLBACK_ENTERPRISE_REVISION "$rollback_enterprise"

kubectl -n "$namespace" get deployment/classic-enterprise-ui >/dev/null

# Inspect the target ReplicaSet before changing the Deployment. The image and
# all release identities must match the approved API/UI rollback set.
target_rs="$({ kubectl -n "$namespace" get rs \
  -l 'app.kubernetes.io/name=classic-enterprise-ui,coomia.com/edition=enterprise' \
  -o 'jsonpath={range .items[*]}{.metadata.annotations.deployment\.kubernetes\.io/revision}{"\t"}{.metadata.name}{"\n"}{end}' \
  | awk -v expected="$revision" '$1 == expected { print $2; exit }'; })"
[[ -n "$target_rs" ]] || fail "rollback revision has no Enterprise UI ReplicaSet"
target_image="$(kubectl -n "$namespace" get rs "$target_rs" -o 'jsonpath={.spec.template.spec.containers[?(@.name=="ui")].image}')"
target_core="$(kubectl -n "$namespace" get rs "$target_rs" -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/core-revision}')"
target_enterprise="$(kubectl -n "$namespace" get rs "$target_rs" -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/enterprise-revision}')"
target_inputs="$(kubectl -n "$namespace" get rs "$target_rs" -o 'jsonpath={.spec.template.metadata.annotations.coomia\.com/release-inputs}')"
[[ "$target_image" == "$rollback_ui_image" ]] || fail "rollback UI ReplicaSet image identity does not match the approved release"
[[ "$target_core" == "$rollback_core" ]] || fail "rollback UI ReplicaSet Core revision does not match the approved release"
[[ "$target_enterprise" == "$rollback_enterprise" ]] || fail "rollback UI ReplicaSet Enterprise revision does not match the approved release"
[[ "$target_inputs" == "$rollback_inputs" ]] || fail "rollback UI ReplicaSet release-inputs digest does not match the approved release"

kubectl -n "$namespace" rollout undo deployment/classic-enterprise-ui --to-revision="$revision"
kubectl -n "$namespace" rollout status deployment/classic-enterprise-ui --timeout=10m

actual_image="$(kubectl -n "$namespace" get deployment/classic-enterprise-ui -o 'jsonpath={.spec.template.spec.containers[?(@.name=="ui")].image}')"
actual_core="$(kubectl -n "$namespace" get deployment/classic-enterprise-ui -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/core-revision}')"
actual_enterprise="$(kubectl -n "$namespace" get deployment/classic-enterprise-ui -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/enterprise-revision}')"
actual_inputs="$(kubectl -n "$namespace" get deployment/classic-enterprise-ui -o 'jsonpath={.spec.template.metadata.annotations.coomia\.com/release-inputs}')"
[[ "$actual_image" == "$rollback_ui_image" ]] || fail "rollback UI image identity does not match the approved release"
[[ "$actual_core" == "$rollback_core" ]] || fail "rollback UI Core revision does not match the approved release"
[[ "$actual_enterprise" == "$rollback_enterprise" ]] || fail "rollback UI Enterprise revision does not match the approved release"
[[ "$actual_inputs" == "$rollback_inputs" ]] || fail "rollback UI release-inputs digest does not match the approved release"

printf 'Enterprise UI rollback verified: namespace=%s revision=%s image=%s\n' \
  "$namespace" "$revision" "$actual_image"
