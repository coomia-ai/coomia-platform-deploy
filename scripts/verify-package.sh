#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
mode="${1:-full}"
failures=0
warnings=0

pass() { printf '[PASS] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; warnings=$((warnings + 1)); }
fail() { printf '[FAIL] %s\n' "$*"; failures=$((failures + 1)); }

[[ "$mode" == "full" || "$mode" == "--layout-only" ]] || {
  echo "usage: $0 [--layout-only]" >&2
  exit 2
}

required=(
  README.md README.en.md AGENTS.md llms.txt LICENSE VERSION RELEASE_STATUS
  CHANGELOG.md CHANGELOG.en.md KNOWN_ISSUES.md KNOWN_ISSUES.en.md
  releases/2026.09.30-trial.6/application-images.env
  releases/2026.09.30-trial.6/README.md releases/2026.09.30-trial.6/README.en.md
  release-manifest.example.md release-manifest.example.en.md install.sh
  compose/.env.example compose/docker-compose.yml compose/docker-compose.app.yml
  compose/docker-compose.admin.yml compose/docker-compose.license-offline.yml
  compose/install.sh compose/manage.sh compose/README.md compose/README.en.md
  compose/config/postgres/init.sh
  kubernetes/10-platform-api.yaml kubernetes/mds-flink-namespace.yaml
  kubernetes/apply-flink-isolation.sh kubernetes/install.sh
  kubernetes/README.md kubernetes/README.en.md
  scripts/init-config.sh scripts/preflight-linux.sh scripts/collect-diagnostics.sh scripts/verify-package.sh
  docs/getting-started.md docs/getting-started.en.md
  docs/architecture.md docs/architecture.en.md
  docs/ai-operations.md docs/ai-operations.en.md
  docs/configuration.md docs/configuration.en.md
  docs/license.md docs/license.en.md
  docs/operations.md docs/operations.en.md
  docs/upgrade-and-backup.md docs/upgrade-and-backup.en.md
  docs/troubleshooting.md docs/troubleshooting.en.md
  docs/security.md docs/security.en.md
  docs/release-readiness.md docs/release-readiness.en.md
  schemas/compose-env.schema.json
)
for rel in "${required[@]}"; do
  [[ -f "$ROOT/$rel" ]] && pass "required file: $rel" || fail "missing file: $rel"
done

while IFS= read -r -d '' script; do
  bash -n "$script" && pass "bash syntax: ${script#$ROOT/}" || fail "bash syntax: ${script#$ROOT/}"
done < <(find "$ROOT" -type f -name '*.sh' -print0)

if find "$ROOT" -type f \( -name '*.py' -o -name '*.pyc' -o -name '*.ts' -o -name '*.tsx' -o -name '*.java' -o -name 'Dockerfile*' \) -print -quit | grep -q .; then
  fail "application source or image-build files found in customer package"
else
  pass "no application source or Dockerfile"
fi

if grep -RIlE --exclude='*.md' --exclude='*.example' --exclude='RELEASE_STATUS' \
  '(BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|Authorization:[[:space:]]*Bearer[[:space:]]+[A-Za-z0-9._-]+)' \
  "$ROOT" >/dev/null 2>&1; then
  fail "possible private key or Bearer token found"
else
  pass "no private key or Bearer token"
fi

if grep -RInE '^[[:space:]]*build:[[:space:]]*' "$ROOT/compose" >/dev/null 2>&1; then
  fail "customer Compose contains an active build block"
else
  pass "customer Compose uses prebuilt images only"
fi

if grep -RInE 'MDS_REPO|k8s/app/|platform-deployment/|[A-Za-z]:\\work\\' \
  "$ROOT/compose" "$ROOT/kubernetes" >/dev/null 2>&1; then
  fail "deployment files depend on a vendor development path"
else
  pass "deployment files are repository-local"
fi

if grep -RInE 'mc[[:space:]]+anonymous[[:space:]]+set[[:space:]]+(public|download|upload)' "$ROOT/compose" >/dev/null 2>&1; then
  fail "object-storage configuration enables anonymous access"
else
  pass "object-storage buckets remain private"
fi

if grep -RInE 'kafka-topics.*--delete|--delete.*kafka-topics|demo[_-]?(topic|data)|seed[_-]?data' \
  "$ROOT/compose" >/dev/null 2>&1; then
  fail "destructive Kafka cleanup or demo seeding found"
else
  pass "no destructive Kafka cleanup or demo seeding"
fi

hardcoded_images="$(grep -RInE '^[[:space:]]*image:' "$ROOT/compose" "$ROOT/kubernetes" \
  --include='*.yml' --include='*.yaml' --include='*.sh' 2>/dev/null | grep -v '\${' || true)"
if [[ -n "$hardcoded_images" ]]; then
  fail "hard-coded image references found; use release variables with RepoDigests"
  printf '%s\n' "$hardcoded_images"
else
  pass "deployment images are supplied through release variables"
fi

if grep -RInE '(change-me|changeme|dbz_pass|password123|admin123|secret123)' \
  "$ROOT/compose" "$ROOT/kubernetes" --include='*.yml' --include='*.yaml' --include='*.env' --include='*.conf' >/dev/null 2>&1; then
  fail "default or example credential found in deployment files"
else
  pass "no known default credential"
fi

if grep -En 'docker([[:space:]]+compose)?[[:space:]]+logs|\.Config\.Env|compose[.]env.*(cat|print)|docker[[:space:]]+volume[[:space:]]+rm|down[[:space:]]+--volumes|system[[:space:]]+prune' \
  "$ROOT/scripts/collect-diagnostics.sh" >/dev/null 2>&1; then
  fail "diagnostic collector contains log, secret, or destructive collection behavior"
else
  pass "diagnostic collector is read-only and excludes logs and container environments"
fi

if command -v python3 >/dev/null 2>&1 && python3 --version >/dev/null 2>&1; then
  python3 -m json.tool "$ROOT/schemas/compose-env.schema.json" >/dev/null \
    && pass "configuration schema is valid JSON" || fail "configuration schema is invalid JSON"
elif command -v jq >/dev/null 2>&1; then
  jq empty "$ROOT/schemas/compose-env.schema.json" >/dev/null \
    && pass "configuration schema is valid JSON" || fail "configuration schema is invalid JSON"
elif command -v node >/dev/null 2>&1 && node --version >/dev/null 2>&1; then
  node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' \
    "$ROOT/schemas/compose-env.schema.json" >/dev/null \
    && pass "configuration schema is valid JSON" || fail "configuration schema is invalid JSON"
else
  warn "python3, jq, or node is required to validate the configuration schema"
fi

image_variables=(
  PLATFORM_API_IMAGE PLATFORM_UI_IMAGE FLINK_LOCAL_IMAGE POSTGRES_IMAGE MINIO_IMAGE
  MINIO_MC_IMAGE NESSIE_IMAGE TUGRAPH_IMAGE DORIS_FE_IMAGE DORIS_BE_IMAGE KAFKA_IMAGE REDIS_IMAGE
)
for name in "${image_variables[@]}"; do
  value="$(sed -n "s/^${name}=//p" "$ROOT/compose/.env.example")"
  [[ -z "$value" ]] && pass "image placeholder is blank: $name" || fail "image placeholder must remain blank: $name"
done

if [[ "$mode" == "full" ]]; then
  release_status="$(sed -n 's/^RELEASE_STATUS=//p' "$ROOT/RELEASE_STATUS")"
  compose_status="$(sed -n 's/^COMPOSE_STATUS=//p' "$ROOT/RELEASE_STATUS")"
  kubernetes_status="$(sed -n 's/^KUBERNETES_STATUS=//p' "$ROOT/RELEASE_STATUS")"
  [[ "$release_status" == "GO" ]] || fail "RELEASE_STATUS is $release_status, expected GO"
  [[ "$compose_status" == "GO" ]] || fail "COMPOSE_STATUS is $compose_status, expected GO"
  [[ "$kubernetes_status" == "GO" ]] || warn "KUBERNETES_STATUS is $kubernetes_status; release must be identified as Compose-only"
  if [[ -f "$ROOT/release-manifest.md" ]]; then
    digest_count="$(grep -Eo '@sha256:[0-9a-f]{64}' "$ROOT/release-manifest.md" | sort -u | wc -l | tr -d ' ')"
    (( digest_count >= 12 )) && pass "release manifest contains immutable image digests" \
      || fail "release-manifest.md does not contain all required image RepoDigests"
  else
    fail "formal release requires release-manifest.md"
  fi
else
  warn "layout-only mode validates package structure but does not approve a release"
fi

echo "result: failures=$failures warnings=$warnings"
(( failures == 0 )) || exit 1
