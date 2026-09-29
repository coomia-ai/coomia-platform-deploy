#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${COOMIA_ENV_FILE:-$SCRIPT_DIR/.env}"
RUNTIME_ENV_FILE="$SCRIPT_DIR/generated/runtime.env"

release_value() {
  sed -n "s/^$1=//p" "$ROOT/RELEASE_STATUS"
}

if [[ "$(release_value RELEASE_STATUS)" != "GO" ]] \
  || [[ "$(release_value COMPOSE_STATUS)" != "GO" ]]; then
  echo "error: this Compose package is not approved for customer installation; see RELEASE_STATUS" >&2
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "error: missing $ENV_FILE" >&2
  echo "run: bash scripts/init-config.sh" >&2
  exit 1
fi
if [[ "$(stat -c '%a' "$ENV_FILE")" != "600" ]]; then
  echo "error: $ENV_FILE must have permission 0600" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

required_images=(
  PLATFORM_API_IMAGE PLATFORM_UI_IMAGE FLINK_LOCAL_IMAGE POSTGRES_IMAGE MINIO_IMAGE
  MINIO_MC_IMAGE NESSIE_IMAGE TUGRAPH_IMAGE DORIS_FE_IMAGE DORIS_BE_IMAGE KAFKA_IMAGE REDIS_IMAGE
)
required_values=(
  DATABASE_URL POSTGRES_USER POSTGRES_PASSWORD POSTGRES_DB MINIO_ROOT_USER MINIO_ROOT_PASSWORD
  DORIS_USER DORIS_PASSWORD REDIS_PASSWORD TUGRAPH_USER TUGRAPH_PASSWORD JWT_SECRET
  DELIVERY_REPORT_HMAC_SECRET DELIVERY_REPORT_HMAC_KEY_ID MDS_FLINK_CONTROL_TOKEN LICENSE_MODE MDS_FLINK_ARTIFACT_DIR
  MDS_GENERATED_CONFIG_DIR MDS_INTAKE_SECRETS_DIR
)

for name in "${required_images[@]}" "${required_values[@]}"; do
  [[ -n "${!name:-}" ]] || { echo "error: $name is empty in $ENV_FILE" >&2; exit 1; }
done

validate_image_digest() {
  local name="$1" image="$2"
  [[ "$image" =~ ^[^[:space:]]+@sha256:[0-9a-f]{64}$ ]] \
    && [[ "$image" != *@sha256:0000000000000000000000000000000000000000000000000000000000000000 ]] || {
    echo "error: $name must be an immutable image RepoDigest" >&2
    exit 1
  }
}
for name in "${required_images[@]}"; do validate_image_digest "$name" "${!name}"; done

[[ "$POSTGRES_USER" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
  echo "error: POSTGRES_USER must be a simple SQL identifier" >&2; exit 1;
}
[[ "$POSTGRES_DB" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
  echo "error: POSTGRES_DB must be a simple SQL identifier" >&2; exit 1;
}
expected_database_url="postgresql+asyncpg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}"
[[ "$DATABASE_URL" == "$expected_database_url" ]] || {
  echo "error: DATABASE_URL must match POSTGRES_USER, POSTGRES_PASSWORD, and POSTGRES_DB" >&2; exit 1;
}
[[ ${#JWT_SECRET} -ge 32 && ${#DELIVERY_REPORT_HMAC_SECRET} -ge 32 ]] || {
  echo "error: application signing secrets must be at least 32 characters" >&2; exit 1;
}
[[ "$JWT_SECRET" != "$DELIVERY_REPORT_HMAC_SECRET" ]] || {
  echo "error: JWT_SECRET and DELIVERY_REPORT_HMAC_SECRET must be different" >&2; exit 1;
}
[[ "$JWT_SECRET" != "change-me-in-production" && "$JWT_SECRET" != "e2e-fake-jwt-for-ui-testing" ]] || {
  echo "error: JWT_SECRET must not use a known default value" >&2; exit 1;
}
[[ "$DELIVERY_REPORT_HMAC_KEY_ID" =~ ^[A-Za-z0-9._-]{1,32}$ ]] || {
  echo "error: DELIVERY_REPORT_HMAC_KEY_ID must use 1-32 safe identifier characters" >&2; exit 1;
}
[[ "$MDS_FLINK_CONTROL_TOKEN" =~ ^[A-Za-z0-9_-]{32,}$ ]] || {
  echo "error: MDS_FLINK_CONTROL_TOKEN must be at least 32 URL-safe characters" >&2; exit 1;
}
[[ ${#DORIS_PASSWORD} -ge 12 ]] || { echo "error: DORIS_PASSWORD must be at least 12 characters" >&2; exit 1; }
for name in POSTGRES_PASSWORD MINIO_ROOT_PASSWORD REDIS_PASSWORD TUGRAPH_PASSWORD; do
  value="${!name}"
  [[ ${#value} -ge 16 ]] || { echo "error: $name must be at least 16 characters" >&2; exit 1; }
done
[[ "$DORIS_USER" == "root" ]] || { echo "error: this Compose release requires DORIS_USER=root" >&2; exit 1; }
[[ "$LICENSE_MODE" == "online" || "$LICENSE_MODE" == "offline" ]] || {
  echo "error: LICENSE_MODE must be online or offline" >&2; exit 1;
}
if [[ "$LICENSE_MODE" == "online" && ! "${LICENSE_SERVER_URL:-}" =~ ^https:// ]]; then
  echo "error: online mode requires an HTTPS LICENSE_SERVER_URL" >&2
  exit 1
fi
if [[ "$LICENSE_MODE" == "offline" ]]; then
  [[ -f "${COOMIA_LICENSE_PUBLIC_KEY_FILE:-}" ]] || {
    echo "error: offline mode requires COOMIA_LICENSE_PUBLIC_KEY_FILE" >&2; exit 1;
  }
fi

validate_private_directory() {
  local name="$1" requested="$2" resolved owner relative
  local -a components
  [[ "$requested" == /* ]] || { echo "error: $name must be an absolute path" >&2; return 1; }
  [[ ! -L "$requested" ]] || { echo "error: $name must not be a symbolic link" >&2; return 1; }
  resolved="$(realpath -m -- "$requested")"
  case "$resolved" in
    /|/bin|/boot|/dev|/etc|/home|/lib|/lib64|/opt|/proc|/root|/run|/sbin|/srv|/sys|/tmp|/usr|/var|/var/lib)
      echo "error: $name must be a dedicated leaf directory" >&2; return 1 ;;
  esac
  relative="${resolved#/}"
  IFS='/' read -r -a components <<< "$relative"
  (( ${#components[@]} >= 3 )) || { echo "error: $name path is too broad" >&2; return 1; }
  if [[ "$resolved" == "$ROOT" || "$resolved" == "$ROOT"/* || "$ROOT" == "$resolved"/* ]]; then
    echo "error: $name must be outside the deployment repository" >&2; return 1
  fi
  if [[ -e "$resolved" ]]; then
    [[ -d "$resolved" && ! -L "$resolved" ]] || { echo "error: $name is not a real directory" >&2; return 1; }
    owner="$(stat -c '%u' -- "$resolved")"
    [[ "$owner" == "$(id -u)" ]] || { echo "error: $name must be owned by the installing user" >&2; return 1; }
  fi
  printf '%s\n' "$resolved"
}

MDS_FLINK_ARTIFACT_DIR="$(validate_private_directory MDS_FLINK_ARTIFACT_DIR "$MDS_FLINK_ARTIFACT_DIR")"
MDS_GENERATED_CONFIG_DIR="$(validate_private_directory MDS_GENERATED_CONFIG_DIR "$MDS_GENERATED_CONFIG_DIR")"
MDS_INTAKE_SECRETS_DIR="$(validate_private_directory MDS_INTAKE_SECRETS_DIR "$MDS_INTAKE_SECRETS_DIR")"
export MDS_FLINK_ARTIFACT_DIR MDS_GENERATED_CONFIG_DIR MDS_INTAKE_SECRETS_DIR

require_disjoint_directories() {
  local left_name="$1" left="$2" right_name="$3" right="$4"
  if [[ "$left" == "$right" || "$left" == "$right"/* || "$right" == "$left"/* ]]; then
    echo "error: $left_name and $right_name must be independent directories" >&2
    exit 1
  fi
}
require_disjoint_directories MDS_FLINK_ARTIFACT_DIR "$MDS_FLINK_ARTIFACT_DIR" MDS_GENERATED_CONFIG_DIR "$MDS_GENERATED_CONFIG_DIR"
require_disjoint_directories MDS_FLINK_ARTIFACT_DIR "$MDS_FLINK_ARTIFACT_DIR" MDS_INTAKE_SECRETS_DIR "$MDS_INTAKE_SECRETS_DIR"
require_disjoint_directories MDS_GENERATED_CONFIG_DIR "$MDS_GENERATED_CONFIG_DIR" MDS_INTAKE_SECRETS_DIR "$MDS_INTAKE_SECRETS_DIR"

umask 077
mkdir -p "$MDS_FLINK_ARTIFACT_DIR" "$MDS_GENERATED_CONFIG_DIR" "$MDS_INTAKE_SECRETS_DIR" "$SCRIPT_DIR/generated"
chmod 700 "$MDS_FLINK_ARTIFACT_DIR" "$MDS_GENERATED_CONFIG_DIR" "$MDS_INTAKE_SECRETS_DIR" "$SCRIPT_DIR/generated"

for name in "${required_images[@]}"; do docker pull "${!name}"; done

FLINK_UNIFIED_ARTIFACT_SHA256="$(docker run --rm --entrypoint sha256sum "$FLINK_LOCAL_IMAGE" /opt/flink/usrlib/flink-intake-job.jar | awk '{print $1}')"
FLINK_LOCAL_ARTIFACT_UID="$(docker run --rm --entrypoint id "$FLINK_LOCAL_IMAGE" -u)"
FLINK_LOCAL_ARTIFACT_GID="$(docker run --rm --entrypoint id "$FLINK_LOCAL_IMAGE" -g)"
[[ "$FLINK_UNIFIED_ARTIFACT_SHA256" =~ ^[0-9a-f]{64}$ ]] || { echo "error: Flink JAR attestation failed" >&2; exit 1; }
[[ "$FLINK_LOCAL_ARTIFACT_UID" =~ ^[1-9][0-9]*$ && "$FLINK_LOCAL_ARTIFACT_GID" =~ ^[1-9][0-9]*$ ]] || {
  echo "error: the Flink image must run as a non-root UID/GID" >&2; exit 1;
}
export FLINK_UNIFIED_ARTIFACT_SHA256 FLINK_LOCAL_ARTIFACT_UID FLINK_LOCAL_ARTIFACT_GID

DORIS_ROOT_PASSWORD_HASH="$(printf '%s' "$DORIS_PASSWORD" | docker run --rm -i --entrypoint python "$PLATFORM_API_IMAGE" -c 'import hashlib,sys; v=sys.stdin.buffer.read(); print("*"+hashlib.sha1(hashlib.sha1(v).digest()).hexdigest().upper())')"
[[ "$DORIS_ROOT_PASSWORD_HASH" =~ ^\*[0-9A-F]{40}$ ]] || { echo "error: Doris password hashing failed" >&2; exit 1; }
DORIS_FE_CONFIG="$MDS_GENERATED_CONFIG_DIR/fe.customer.conf"
{
  sed '/^[[:space:]]*initial_root_password[[:space:]]*=/d' "$SCRIPT_DIR/config/doris/fe.conf"
  printf '\ninitial_root_password = %s\n' "$DORIS_ROOT_PASSWORD_HASH"
} > "$DORIS_FE_CONFIG"
chmod 600 "$DORIS_FE_CONFIG"
export DORIS_FE_CONFIG

cat > "$RUNTIME_ENV_FILE" <<EOF
FLINK_UNIFIED_ARTIFACT_SHA256=$FLINK_UNIFIED_ARTIFACT_SHA256
FLINK_LOCAL_ARTIFACT_UID=$FLINK_LOCAL_ARTIFACT_UID
FLINK_LOCAL_ARTIFACT_GID=$FLINK_LOCAL_ARTIFACT_GID
DORIS_FE_CONFIG=$DORIS_FE_CONFIG
EOF
chmod 600 "$RUNTIME_ENV_FILE"

files=(-f "$SCRIPT_DIR/docker-compose.yml" -f "$SCRIPT_DIR/docker-compose.app.yml")
if [[ "$LICENSE_MODE" == "offline" ]]; then files+=(-f "$SCRIPT_DIR/docker-compose.license-offline.yml"); fi
compose=(docker compose --env-file "$ENV_FILE" "${files[@]}")
"${compose[@]}" config --quiet
"${compose[@]}" up -d --wait --wait-timeout "${INSTALL_WAIT_TIMEOUT_SECONDS:-600}"

echo "installation complete"
echo "UI:  http://localhost:${PLATFORM_UI_PORT:-3000}"
echo "API: http://localhost:${PLATFORM_API_PORT:-8050}/health"
echo "next: register the first account, then run 'bash compose/manage.sh restart-api' once"
