#!/usr/bin/env bash
set -euo pipefail

namespace="${CLASSIC_ENTERPRISE_NAMESPACE:-classic-enterprise}"
flink_namespace="${CLASSIC_ENTERPRISE_FLINK_NAMESPACE:-classic-enterprise-flink}"
api_image="${CLASSIC_ENTERPRISE_API_IMAGE:-}"
ui_image="${CLASSIC_ENTERPRISE_UI_IMAGE:-}"
core_revision="${CLASSIC_ENTERPRISE_CORE_REVISION:-}"
enterprise_revision="${CLASSIC_ENTERPRISE_ENTERPRISE_REVISION:-}"
deployment_revision="${CLASSIC_ENTERPRISE_DEPLOYMENT_REVISION:-}"
release_inputs="${CLASSIC_ENTERPRISE_RELEASE_INPUTS:-}"
timeout="${CLASSIC_ENTERPRISE_VERIFY_TIMEOUT:-10m}"
ingress_host="${CLASSIC_ENTERPRISE_INGRESS_HOST:-}"
ingress_tls_secret="${CLASSIC_ENTERPRISE_INGRESS_TLS_SECRET:-}"
ingress_namespace="${CLASSIC_ENTERPRISE_INGRESS_NAMESPACE:-}"

fail() {
  echo "error: $*" >&2
  exit 1
}

validate_namespace() {
  local value="$1"
  [[ "$value" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] || fail "namespace must be a DNS label"
  [[ ${#value} -le 63 ]] || fail "namespace is too long"
  case "$value" in
    mds-app|mds-flink|data-infra|mds-m2-acceptance)
      fail "Enterprise verification cannot target reserved namespace '$value'"
      ;;
  esac
}

validate_revision() {
  local name="$1" value="$2"
  [[ "$value" =~ ^[0-9a-f]{7,64}$ ]] || fail "$name must be lowercase hexadecimal"
}

validate_digest() {
  local name="$1" value="$2"
  [[ "$value" =~ ^.+@sha256:[0-9a-f]{64}$ ]] || fail "$name must be an immutable RepoDigest"
  [[ "$value" != *@sha256:0000000000000000000000000000000000000000000000000000000000000000 ]] || fail "$name cannot use a zero digest"
}

validate_hostname() {
  local name="$1" value="$2"
  [[ ${#value} -le 253 && "$value" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*$ ]] \
    || fail "$name must be a lowercase DNS hostname"
}

validate_secret_name() {
  local name="$1" value="$2"
  local pattern='^([a-z0-9]([-a-z0-9]*[a-z0-9])?)(\.([a-z0-9]([-a-z0-9]*[a-z0-9])?))*$'
  [[ ${#value} -le 253 && "$value" =~ $pattern ]] || fail "$name must be a DNS subdomain"
}

validate_namespace "$namespace"
validate_namespace "$flink_namespace"
[[ "$namespace" != "$flink_namespace" ]] || fail "Enterprise API and Flink namespaces must be distinct"
if [[ -n "$ingress_host" || -n "$ingress_tls_secret" || -n "$ingress_namespace" ]]; then
  [[ -n "$ingress_host" && -n "$ingress_tls_secret" && -n "$ingress_namespace" ]] || {
    fail "CLASSIC_ENTERPRISE_INGRESS_HOST, CLASSIC_ENTERPRISE_INGRESS_TLS_SECRET, and CLASSIC_ENTERPRISE_INGRESS_NAMESPACE must be provided together"
  }
  validate_hostname CLASSIC_ENTERPRISE_INGRESS_HOST "$ingress_host"
  validate_secret_name CLASSIC_ENTERPRISE_INGRESS_TLS_SECRET "$ingress_tls_secret"
  validate_namespace "$ingress_namespace"
  [[ -n "$ui_image" ]] || fail "CLASSIC_ENTERPRISE_UI_IMAGE is required for an Enterprise root route"
fi
command -v kubectl >/dev/null 2>&1 || fail "kubectl is required"
[[ -n "$api_image" ]] || fail "CLASSIC_ENTERPRISE_API_IMAGE is required"
validate_digest CLASSIC_ENTERPRISE_API_IMAGE "$api_image"
if [[ -n "$ui_image" ]]; then
  validate_digest CLASSIC_ENTERPRISE_UI_IMAGE "$ui_image"
fi
validate_revision CLASSIC_ENTERPRISE_CORE_REVISION "$core_revision"
validate_revision CLASSIC_ENTERPRISE_ENTERPRISE_REVISION "$enterprise_revision"
validate_revision CLASSIC_ENTERPRISE_DEPLOYMENT_REVISION "$deployment_revision"
[[ "$release_inputs" =~ ^[0-9a-f]{64}$ ]] || fail "CLASSIC_ENTERPRISE_RELEASE_INPUTS must be a SHA-256"
release_inputs_label="${release_inputs:0:63}"

equals() {
  local name="$1" expected="$2" actual="$3"
  [[ "$actual" == "$expected" ]] || fail "$name does not match the approved release"
}

namespace_role="$(kubectl get namespace "$namespace" -o 'jsonpath={.metadata.labels.coomia\.com/role}')"
namespace_isolation="$(kubectl get namespace "$namespace" -o 'jsonpath={.metadata.labels.coomia\.com/isolation}')"
namespace_core="$(kubectl get namespace "$namespace" -o 'jsonpath={.metadata.labels.coomia\.com/core-revision}')"
namespace_enterprise="$(kubectl get namespace "$namespace" -o 'jsonpath={.metadata.labels.coomia\.com/enterprise-revision}')"
namespace_deployment="$(kubectl get namespace "$namespace" -o 'jsonpath={.metadata.labels.coomia\.com/deployment-revision}')"
namespace_inputs="$(kubectl get namespace "$namespace" -o 'jsonpath={.metadata.annotations.coomia\.com/release-inputs}')"
namespace_inputs_label="$(kubectl get namespace "$namespace" -o 'jsonpath={.metadata.labels.coomia\.com/release-inputs}')"
equals "namespace role" classic-enterprise "$namespace_role"
equals "namespace isolation" dedicated "$namespace_isolation"
equals "namespace Core revision" "$core_revision" "$namespace_core"
equals "namespace Enterprise revision" "$enterprise_revision" "$namespace_enterprise"
equals "namespace Deployment revision" "$deployment_revision" "$namespace_deployment"
equals "namespace release-inputs" "$release_inputs" "$namespace_inputs"
equals "namespace release-inputs label" "$release_inputs_label" "$namespace_inputs_label"

flink_role="$(kubectl get namespace "$flink_namespace" -o 'jsonpath={.metadata.labels.coomia\.com/role}')"
flink_isolation="$(kubectl get namespace "$flink_namespace" -o 'jsonpath={.metadata.labels.coomia\.com/isolation}')"
flink_core="$(kubectl get namespace "$flink_namespace" -o 'jsonpath={.metadata.labels.coomia\.com/core-revision}')"
flink_enterprise="$(kubectl get namespace "$flink_namespace" -o 'jsonpath={.metadata.labels.coomia\.com/enterprise-revision}')"
flink_deployment="$(kubectl get namespace "$flink_namespace" -o 'jsonpath={.metadata.labels.coomia\.com/deployment-revision}')"
flink_inputs="$(kubectl get namespace "$flink_namespace" -o 'jsonpath={.metadata.annotations.coomia\.com/release-inputs}')"
flink_inputs_label="$(kubectl get namespace "$flink_namespace" -o 'jsonpath={.metadata.labels.coomia\.com/release-inputs}')"
equals "Flink namespace role" classic-enterprise-flink "$flink_role"
equals "Flink namespace isolation" dedicated "$flink_isolation"
equals "Flink namespace Core revision" "$core_revision" "$flink_core"
equals "Flink namespace Enterprise revision" "$enterprise_revision" "$flink_enterprise"
equals "Flink namespace revision" "$deployment_revision" "$flink_deployment"
equals "Flink namespace release-inputs" "$release_inputs" "$flink_inputs"
equals "Flink namespace release-inputs label" "$release_inputs_label" "$flink_inputs_label"

deployment_image="$(kubectl -n "$namespace" get deployment classic-enterprise-api -o 'jsonpath={.spec.template.spec.containers[?(@.name=="api")].image}')"
deployment_core="$(kubectl -n "$namespace" get deployment classic-enterprise-api -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/core-revision}')"
deployment_enterprise="$(kubectl -n "$namespace" get deployment classic-enterprise-api -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/enterprise-revision}')"
deployment_revision_actual="$(kubectl -n "$namespace" get deployment classic-enterprise-api -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/deployment-revision}')"
deployment_inputs="$(kubectl -n "$namespace" get deployment classic-enterprise-api -o 'jsonpath={.spec.template.metadata.annotations.coomia\.com/release-inputs}')"
deployment_inputs_label="$(kubectl -n "$namespace" get deployment classic-enterprise-api -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/release-inputs}')"
deployment_edition="$(kubectl -n "$namespace" get deployment classic-enterprise-api -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/edition}')"
deployment_isolation="$(kubectl -n "$namespace" get deployment classic-enterprise-api -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/isolation}')"
equals "Deployment image" "$api_image" "$deployment_image"
equals "Deployment Core revision" "$core_revision" "$deployment_core"
equals "Deployment Enterprise revision" "$enterprise_revision" "$deployment_enterprise"
equals "Deployment revision" "$deployment_revision" "$deployment_revision_actual"
equals "Deployment release-inputs" "$release_inputs" "$deployment_inputs"
equals "Deployment release-inputs label" "$release_inputs_label" "$deployment_inputs_label"
equals "Deployment edition" enterprise "$deployment_edition"
equals "Deployment isolation" dedicated "$deployment_isolation"

service_name="$(kubectl -n "$namespace" get service classic-enterprise-api -o 'jsonpath={.spec.selector.app\.kubernetes\.io/name}')"
service_edition="$(kubectl -n "$namespace" get service classic-enterprise-api -o 'jsonpath={.spec.selector.coomia\.com/edition}')"
service_port="$(kubectl -n "$namespace" get service classic-enterprise-api -o 'jsonpath={.spec.ports[?(@.name=="http")].port}')"
service_target_port="$(kubectl -n "$namespace" get service classic-enterprise-api -o 'jsonpath={.spec.ports[?(@.name=="http")].targetPort}')"
equals "Service selector" classic-enterprise-api "$service_name"
equals "Service edition selector" enterprise "$service_edition"
equals "Service HTTP port" 8050 "$service_port"
equals "Service HTTP targetPort" 8050 "$service_target_port"

if [[ -n "$ui_image" ]]; then
  ui_deployment_image="$(kubectl -n "$namespace" get deployment classic-enterprise-ui -o 'jsonpath={.spec.template.spec.containers[?(@.name=="ui")].image}')"
  ui_deployment_core="$(kubectl -n "$namespace" get deployment classic-enterprise-ui -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/core-revision}')"
  ui_deployment_enterprise="$(kubectl -n "$namespace" get deployment classic-enterprise-ui -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/enterprise-revision}')"
  ui_deployment_revision="$(kubectl -n "$namespace" get deployment classic-enterprise-ui -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/deployment-revision}')"
  ui_deployment_inputs="$(kubectl -n "$namespace" get deployment classic-enterprise-ui -o 'jsonpath={.spec.template.metadata.annotations.coomia\.com/release-inputs}')"
  ui_deployment_inputs_label="$(kubectl -n "$namespace" get deployment classic-enterprise-ui -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/release-inputs}')"
  ui_deployment_edition="$(kubectl -n "$namespace" get deployment classic-enterprise-ui -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/edition}')"
  ui_deployment_isolation="$(kubectl -n "$namespace" get deployment classic-enterprise-ui -o 'jsonpath={.spec.template.metadata.labels.coomia\.com/isolation}')"
  equals "UI Deployment image" "$ui_image" "$ui_deployment_image"
  equals "UI Deployment Core revision" "$core_revision" "$ui_deployment_core"
  equals "UI Deployment Enterprise revision" "$enterprise_revision" "$ui_deployment_enterprise"
  equals "UI Deployment revision" "$deployment_revision" "$ui_deployment_revision"
  equals "UI Deployment release-inputs" "$release_inputs" "$ui_deployment_inputs"
  equals "UI Deployment release-inputs label" "$release_inputs_label" "$ui_deployment_inputs_label"
  equals "UI Deployment edition" enterprise "$ui_deployment_edition"
  equals "UI Deployment isolation" dedicated "$ui_deployment_isolation"
  ui_service_name="$(kubectl -n "$namespace" get service classic-enterprise-ui -o 'jsonpath={.spec.selector.app\.kubernetes\.io/name}')"
  ui_service_edition="$(kubectl -n "$namespace" get service classic-enterprise-ui -o 'jsonpath={.spec.selector.coomia\.com/edition}')"
  ui_service_port="$(kubectl -n "$namespace" get service classic-enterprise-ui -o 'jsonpath={.spec.ports[?(@.name=="http")].port}')"
  ui_service_target_port="$(kubectl -n "$namespace" get service classic-enterprise-ui -o 'jsonpath={.spec.ports[?(@.name=="http")].targetPort}')"
  equals "UI Service selector" classic-enterprise-ui "$ui_service_name"
  equals "UI Service edition selector" enterprise "$ui_service_edition"
  equals "UI Service HTTP port" 3000 "$ui_service_port"
  equals "UI Service HTTP targetPort" 3000 "$ui_service_target_port"
  ui_endpoint_ips="$(kubectl -n "$namespace" get endpoints classic-enterprise-ui -o 'jsonpath={.subsets[*].addresses[*].ip}')"
  ui_endpoint_ports="$(kubectl -n "$namespace" get endpoints classic-enterprise-ui -o 'jsonpath={.subsets[*].ports[?(@.name=="http")].port}')"
  [[ -n "$ui_endpoint_ips" ]] || fail "Enterprise UI Service has no ready endpoints"
  [[ "$ui_endpoint_ports" == *3000* ]] || fail "Enterprise UI Service endpoints do not expose HTTP port 3000"
fi

endpoint_ips="$(kubectl -n "$namespace" get endpoints classic-enterprise-api -o 'jsonpath={.subsets[*].addresses[*].ip}')"
endpoint_ports="$(kubectl -n "$namespace" get endpoints classic-enterprise-api -o 'jsonpath={.subsets[*].ports[?(@.name=="http")].port}')"
[[ -n "$endpoint_ips" ]] || fail "Enterprise Service has no ready endpoints"
[[ "$endpoint_ports" == *8050* ]] || fail "Enterprise Service endpoints do not expose HTTP port 8050"

config_edition="$(kubectl -n "$namespace" get configmap classic-enterprise-api-config -o 'jsonpath={.data.EDITION}')"
config_contract="$(kubectl -n "$namespace" get configmap classic-enterprise-api-config -o 'jsonpath={.data.COOMIA_CONTRACT_MODE}')"
config_license="$(kubectl -n "$namespace" get configmap classic-enterprise-api-config -o 'jsonpath={.data.LICENSE_ENFORCEMENT}')"
config_flink_namespace="$(kubectl -n "$namespace" get configmap classic-enterprise-api-config -o 'jsonpath={.data.FLINK_K8S_NAMESPACE}')"
config_scope="$(kubectl -n "$namespace" get configmap classic-enterprise-api-config -o 'jsonpath={.metadata.labels.coomia\.com/data-scope}')"
equals "ConfigMap edition" enterprise "$config_edition"
equals "ConfigMap contract mode" open_core "$config_contract"
equals "ConfigMap License enforcement" true "$config_license"
equals "ConfigMap Flink namespace" "$flink_namespace" "$config_flink_namespace"
equals "ConfigMap data scope" enterprise "$config_scope"

kubectl -n "$namespace" get serviceaccount classic-enterprise-api >/dev/null
kubectl -n "$namespace" get pvc classic-enterprise-license >/dev/null
kubectl -n "$namespace" get configmap classic-enterprise-schema-baseline >/dev/null
kubectl -n "$namespace" get secret classic-enterprise-api-secret >/dev/null

secret_scope="$(kubectl -n "$namespace" get secret classic-enterprise-api-secret -o 'jsonpath={.metadata.labels.coomia\.com/data-scope}')"
equals "Enterprise API Secret data scope" enterprise "$secret_scope"
# Ask kubectl for key names only. The Secret object is never placed in a shell
# variable, log, or release artifact, so verification cannot expose payloads.
secret_keys="$(kubectl -n "$namespace" get secret classic-enterprise-api-secret \
  -o 'go-template={{range $key, $_ := .data}}{{$key}}{{"\n"}}{{end}}')"
for required_secret_key in \
  DATABASE_URL MINIO_ACCESS_KEY MINIO_SECRET_KEY S3_ACCESS_KEY S3_SECRET_KEY \
  DORIS_PASSWORD REDIS_PASSWORD TUGRAPH_PASSWORD JWT_SECRET DELIVERY_REPORT_HMAC_SECRET; do
  grep -Fxq "$required_secret_key" <<<"$secret_keys" \
    || fail "Enterprise API Secret is missing required key $required_secret_key"
done

api_config_refs="$(kubectl -n "$namespace" get deployment classic-enterprise-api -o 'jsonpath={.spec.template.spec.containers[?(@.name=="api")].envFrom[*].configMapRef.name}')"
api_secret_refs="$(kubectl -n "$namespace" get deployment classic-enterprise-api -o 'jsonpath={.spec.template.spec.containers[?(@.name=="api")].envFrom[*].secretRef.name}')"
[[ "$api_config_refs" == *classic-enterprise-api-config* ]] || fail "Enterprise API does not reference its namespace-local ConfigMap"
[[ "$api_secret_refs" == *classic-enterprise-api-secret* ]] || fail "Enterprise API does not reference its namespace-local Secret"
[[ "$api_secret_refs" != *platform-api-secret* && "$api_secret_refs" != *mds-* ]] || fail "Enterprise API references an M2 or shared Secret"

license_scope="$(kubectl -n "$namespace" get pvc classic-enterprise-license -o 'jsonpath={.metadata.labels.coomia\.com/data-scope}')"
equals "License PVC data scope" enterprise-license "$license_scope"
baseline_namespace="$(kubectl -n "$namespace" get configmap classic-enterprise-schema-baseline -o 'jsonpath={.metadata.namespace}')"
baseline_scope="$(kubectl -n "$namespace" get configmap classic-enterprise-schema-baseline -o 'jsonpath={.metadata.labels.coomia\.com/data-scope}')"
equals "Schema baseline namespace" "$namespace" "$baseline_namespace"
equals "Schema baseline data scope" enterprise "$baseline_scope"

policy_yaml="$(kubectl -n "$namespace" get networkpolicy classic-enterprise-api-ingress -o yaml)"
grep -Fq 'name: classic-enterprise-api-ingress' <<<"$policy_yaml" || fail "Enterprise NetworkPolicy identity is missing"
grep -Fq 'coomia.com/edition: enterprise' <<<"$policy_yaml" || fail "Enterprise NetworkPolicy selector is missing"
grep -Fq 'podSelector: {}' <<<"$policy_yaml" || fail "same-namespace Enterprise ingress selector is missing"
if grep -Fq 'ipBlock:' <<<"$policy_yaml"; then
  fail "Enterprise NetworkPolicy must not allow arbitrary IP blocks"
fi

if [[ -n "$ingress_host" ]]; then
  ingress_yaml="$(kubectl -n "$namespace" get ingress classic-enterprise-api -o yaml)"
  grep -Fq "ingressClassName: nginx" <<<"$ingress_yaml" || fail "Enterprise Ingress class is missing"
  grep -Fq "host: $ingress_host" <<<"$ingress_yaml" || fail "Enterprise Ingress host does not match"
  grep -Fq "secretName: $ingress_tls_secret" <<<"$ingress_yaml" || fail "Enterprise Ingress TLS secret does not match"
  grep -Fq "path: /api/copilotkit" <<<"$ingress_yaml" || fail "Enterprise Ingress CopilotKit route is missing"
  grep -Fq "path: /" <<<"$ingress_yaml" || fail "Enterprise Ingress root route is missing"
  grep -Fq 'name: classic-enterprise-ui' <<<"$ingress_yaml" || fail "Enterprise Ingress root route does not target the UI Service"
fi

kubectl -n "$namespace" rollout status deployment/classic-enterprise-api --timeout="$timeout" >/dev/null
if [[ -n "$ui_image" ]]; then
  ui_policy_yaml="$(kubectl -n "$namespace" get networkpolicy classic-enterprise-ui-ingress -o yaml)"
  grep -Fq 'name: classic-enterprise-ui-ingress' <<<"$ui_policy_yaml" || fail "Enterprise UI NetworkPolicy identity is missing"
  grep -Fq 'coomia.com/edition: enterprise' <<<"$ui_policy_yaml" || fail "Enterprise UI NetworkPolicy selector is missing"
  grep -Fq 'podSelector: {}' <<<"$ui_policy_yaml" || fail "same-namespace Enterprise UI ingress selector is missing"
  if grep -Fq 'ipBlock:' <<<"$ui_policy_yaml"; then
    fail "Enterprise UI NetworkPolicy must not allow arbitrary IP blocks"
  fi
  kubectl -n "$namespace" rollout status deployment/classic-enterprise-ui --timeout="$timeout" >/dev/null
fi
printf 'Enterprise isolation verified: namespace=%s api=%s ui=%s\n' "$namespace" "$api_image" "${ui_image:-disabled}"
