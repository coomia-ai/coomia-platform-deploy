#!/usr/bin/env bash
set -euo pipefail

namespace="${CLASSIC_ENTERPRISE_NAMESPACE:-classic-enterprise}"
revision="${1:-}"

fail() {
  echo "error: $*" >&2
  exit 1
}

[[ -n "$revision" && "$revision" != -* ]] || {
  echo "usage: CONFIRM_ENTERPRISE_ROLLBACK=YES CLASSIC_ENTERPRISE_ROLLBACK_IMAGE=repo@sha256:<digest> [CLASSIC_ENTERPRISE_ROLLBACK_UI_IMAGE=repo@sha256:<digest> CLASSIC_ENTERPRISE_ROLLBACK_UI_REVISION=<ui-revision>] CLASSIC_ENTERPRISE_ROLLBACK_CORE_REVISION=<rev> CLASSIC_ENTERPRISE_ROLLBACK_ENTERPRISE_REVISION=<rev> CLASSIC_ENTERPRISE_ROLLBACK_RELEASE_INPUTS=<sha256> $0 API_REVISION" >&2
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
rollback_image="${CLASSIC_ENTERPRISE_ROLLBACK_IMAGE:-}"
rollback_core="${CLASSIC_ENTERPRISE_ROLLBACK_CORE_REVISION:-}"
rollback_enterprise="${CLASSIC_ENTERPRISE_ROLLBACK_ENTERPRISE_REVISION:-}"
rollback_inputs="${CLASSIC_ENTERPRISE_ROLLBACK_RELEASE_INPUTS:-}"
rollback_ui_image="${CLASSIC_ENTERPRISE_ROLLBACK_UI_IMAGE:-}"
rollback_ui_revision="${CLASSIC_ENTERPRISE_ROLLBACK_UI_REVISION:-}"
[[ -n "$rollback_image" ]] || fail "CLASSIC_ENTERPRISE_ROLLBACK_IMAGE is required"
[[ -n "$rollback_core" ]] || fail "CLASSIC_ENTERPRISE_ROLLBACK_CORE_REVISION is required"
[[ -n "$rollback_enterprise" ]] || fail "CLASSIC_ENTERPRISE_ROLLBACK_ENTERPRISE_REVISION is required"
[[ "$rollback_inputs" =~ ^[0-9a-f]{64}$ ]] || fail "CLASSIC_ENTERPRISE_ROLLBACK_RELEASE_INPUTS must be a SHA-256"
validate_digest CLASSIC_ENTERPRISE_ROLLBACK_IMAGE "$rollback_image"
if [[ -n "$rollback_ui_image" ]]; then
  validate_digest CLASSIC_ENTERPRISE_ROLLBACK_UI_IMAGE "$rollback_ui_image"
  [[ "$rollback_ui_revision" =~ ^[1-9][0-9]*$ ]] || {
    fail "CLASSIC_ENTERPRISE_ROLLBACK_UI_REVISION must be the UI Deployment's positive rollout revision"
  }
elif kubectl -n "$namespace" get deployment classic-enterprise-ui >/dev/null 2>&1; then
  fail "CLASSIC_ENTERPRISE_ROLLBACK_UI_IMAGE is required when the Enterprise UI Deployment exists"
fi
validate_revision CLASSIC_ENTERPRISE_ROLLBACK_CORE_REVISION "$rollback_core"
validate_revision CLASSIC_ENTERPRISE_ROLLBACK_ENTERPRISE_REVISION "$rollback_enterprise"

kubectl -n "$namespace" get deployment classic-enterprise-api >/dev/null

# Inspect the target ReplicaSet before changing the live Deployment.  A rollout
# revision is only safe to select when its immutable image and release labels
# match the approved rollback identity.
target_rs="$({ kubectl -n "$namespace" get rs \
  -l 'app.kubernetes.io/name=classic-enterprise-api,coomia.com/edition=enterprise' \
  -o 'jsonpath={range .items[*]}{.metadata.annotations.deployment\.kubernetes\.io/revision}{"\t"}{.metadata.name}{"\n"}{end}' \
  | awk -v expected="$revision" '$1 == expected { print $2; exit }'; })"
[[ -n "$target_rs" ]] || fail "rollback revision has no Enterprise ReplicaSet"
target_image="$(kubectl -n "$namespace" get rs "$target_rs" -o 'jsonpath={.spec.template.spec.containers[?(@.name=="api")].image}')"
target_core="$(kubectl -n "$namespace" get rs "$target_rs" -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/core-revision}')"
target_enterprise="$(kubectl -n "$namespace" get rs "$target_rs" -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/enterprise-revision}')"
target_inputs="$(kubectl -n "$namespace" get rs "$target_rs" -o 'jsonpath={.spec.template.metadata.annotations.coomia\.com/release-inputs}')"
[[ "$target_image" == "$rollback_image" ]] || fail "rollback ReplicaSet image identity does not match the approved release"
[[ "$target_core" == "$rollback_core" ]] || fail "rollback ReplicaSet Core revision does not match the approved release"
[[ "$target_enterprise" == "$rollback_enterprise" ]] || fail "rollback ReplicaSet Enterprise revision does not match the approved release"
[[ "$target_inputs" == "$rollback_inputs" ]] || fail "rollback ReplicaSet release-inputs digest does not match the approved release"

ui_target_rs=""
if [[ -n "$rollback_ui_image" ]]; then
  ui_target_rs="$({ kubectl -n "$namespace" get rs \
    -l 'app.kubernetes.io/name=classic-enterprise-ui,coomia.com/edition=enterprise' \
    -o 'jsonpath={range .items[*]}{.metadata.annotations.deployment\.kubernetes\.io/revision}{"\t"}{.metadata.name}{"\n"}{end}' \
    | awk -v expected="$rollback_ui_revision" '$1 == expected { print $2; exit }'; })"
  [[ -n "$ui_target_rs" ]] || fail "rollback revision has no Enterprise UI ReplicaSet"
  ui_target_image="$(kubectl -n "$namespace" get rs "$ui_target_rs" -o 'jsonpath={.spec.template.spec.containers[?(@.name=="ui")].image}')"
  ui_target_core="$(kubectl -n "$namespace" get rs "$ui_target_rs" -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/core-revision}')"
  ui_target_enterprise="$(kubectl -n "$namespace" get rs "$ui_target_rs" -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/enterprise-revision}')"
  ui_target_inputs="$(kubectl -n "$namespace" get rs "$ui_target_rs" -o 'jsonpath={.spec.template.metadata.annotations.coomia\.com/release-inputs}')"
  [[ "$ui_target_image" == "$rollback_ui_image" ]] || fail "rollback UI ReplicaSet image identity does not match the approved release"
  [[ "$ui_target_core" == "$rollback_core" ]] || fail "rollback UI ReplicaSet Core revision does not match the approved release"
  [[ "$ui_target_enterprise" == "$rollback_enterprise" ]] || fail "rollback UI ReplicaSet Enterprise revision does not match the approved release"
  [[ "$ui_target_inputs" == "$rollback_inputs" ]] || fail "rollback UI ReplicaSet release-inputs digest does not match the approved release"
fi

kubectl -n "$namespace" rollout undo deployment/classic-enterprise-api --to-revision="$revision"
kubectl -n "$namespace" rollout status deployment/classic-enterprise-api --timeout=10m
if [[ -n "$rollback_ui_image" ]]; then
  kubectl -n "$namespace" rollout undo deployment/classic-enterprise-ui --to-revision="$rollback_ui_revision"
  kubectl -n "$namespace" rollout status deployment/classic-enterprise-ui --timeout=10m
fi

actual_image="$(kubectl -n "$namespace" get deployment classic-enterprise-api -o 'jsonpath={.spec.template.spec.containers[?(@.name=="api")].image}')"
actual_core="$(kubectl -n "$namespace" get deployment classic-enterprise-api -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/core-revision}')"
actual_enterprise="$(kubectl -n "$namespace" get deployment classic-enterprise-api -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/enterprise-revision}')"
actual_inputs="$(kubectl -n "$namespace" get deployment classic-enterprise-api -o 'jsonpath={.spec.template.metadata.annotations.coomia\.com/release-inputs}')"

[[ "$actual_image" == "$rollback_image" ]] || fail "rollback image identity does not match the approved release"
[[ "$actual_core" == "$rollback_core" ]] || fail "rollback Core revision does not match the approved release"
[[ "$actual_enterprise" == "$rollback_enterprise" ]] || fail "rollback Enterprise revision does not match the approved release"
[[ "$actual_inputs" == "$rollback_inputs" ]] || fail "rollback release-inputs digest does not match the approved release"
if [[ -n "$rollback_ui_image" ]]; then
  actual_ui_image="$(kubectl -n "$namespace" get deployment classic-enterprise-ui -o 'jsonpath={.spec.template.spec.containers[?(@.name=="ui")].image}')"
  actual_ui_core="$(kubectl -n "$namespace" get deployment classic-enterprise-ui -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/core-revision}')"
  actual_ui_enterprise="$(kubectl -n "$namespace" get deployment classic-enterprise-ui -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/enterprise-revision}')"
  actual_ui_inputs="$(kubectl -n "$namespace" get deployment classic-enterprise-ui -o 'jsonpath={.spec.template.metadata.annotations.coomia\.com/release-inputs}')"
  [[ "$actual_ui_image" == "$rollback_ui_image" ]] || fail "rollback UI image identity does not match the approved release"
  [[ "$actual_ui_core" == "$rollback_core" ]] || fail "rollback UI Core revision does not match the approved release"
  [[ "$actual_ui_enterprise" == "$rollback_enterprise" ]] || fail "rollback UI Enterprise revision does not match the approved release"
  [[ "$actual_ui_inputs" == "$rollback_inputs" ]] || fail "rollback UI release-inputs digest does not match the approved release"
fi
printf 'Enterprise rollback verified: namespace=%s api_revision=%s ui_revision=%s ui=%s\n' "$namespace" "$revision" "${rollback_ui_revision:-disabled}" "${rollback_ui_image:-disabled}"
