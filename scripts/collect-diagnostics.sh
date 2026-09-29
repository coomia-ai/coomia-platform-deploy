#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${COOMIA_ENV_FILE:-$ROOT/compose/.env}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
output_file="$ROOT/diagnostics/coomia-diagnostics-$timestamp.txt"

usage() {
  echo "usage: $0 [--output FILE]" >&2
}

while (( $# > 0 )); do
  case "$1" in
    --output)
      (( $# >= 2 )) || { usage; exit 2; }
      output_file="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ "$output_file" != /* ]]; then
  output_file="$PWD/$output_file"
fi
output_dir="$(dirname -- "$output_file")"
umask 077
mkdir -p "$output_dir"
: > "$output_file"
chmod 600 "$output_file"

section() {
  printf '\n## %s\n' "$1"
}

run_read_only() {
  local label="$1"
  shift
  printf '\n### %s\n' "$label"
  if ! command -v "$1" >/dev/null 2>&1; then
    printf '[unavailable] command not found: %s\n' "$1"
    return 0
  fi
  "$@" 2>&1 || printf '[command failed: exit=%s]\n' "$?"
}

env_value() {
  local name="$1" fallback="$2" value
  if [[ ! -f "$ENV_FILE" ]]; then
    printf '%s\n' "$fallback"
    return
  fi
  value="$(sed -n "s/^${name}=//p" "$ENV_FILE" | tail -n 1)"
  if [[ -n "$value" ]]; then printf '%s\n' "$value"; else printf '%s\n' "$fallback"; fi
}

http_status() {
  local url="$1" code
  if code="$(curl --noproxy '*' -sS -o /dev/null -w '%{http_code}' --max-time 5 "$url" 2>/dev/null)"; then
    printf '%s\n' "$code"
  else
    printf 'unavailable\n'
  fi
}

api_port="$(env_value PLATFORM_API_PORT 8050)"
ui_port="$(env_value PLATFORM_UI_PORT 3000)"
[[ "$api_port" =~ ^[0-9]{1,5}$ ]] || api_port=8050
[[ "$ui_port" =~ ^[0-9]{1,5}$ ]] || ui_port=3000

{
  printf '# Coomia AI Data Platform Diagnostic Report\n'
  printf 'generated_utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'classification: customer-confidential\n'
  printf 'collection_mode: read-only, redacted\n'
  printf 'excluded: environment values, License content, private keys, container environment variables, application logs\n'

  section "Release"
  if [[ -f "$ROOT/VERSION" ]]; then printf 'version: %s\n' "$(tr -d '\r\n' < "$ROOT/VERSION")"; else echo 'version: unavailable'; fi
  if [[ -f "$ROOT/RELEASE_STATUS" ]]; then sed 's/^/status: /' "$ROOT/RELEASE_STATUS"; else echo 'release_status: unavailable'; fi
  printf 'repository_root: %s\n' "$ROOT"

  section "Configuration Presence"
  if [[ -f "$ENV_FILE" ]]; then
    printf 'compose_env: present\n'
    printf 'compose_env_mode: %s\n' "$(stat -c '%a' "$ENV_FILE" 2>/dev/null || echo unavailable)"
    printf 'license_mode: %s\n' "$(env_value LICENSE_MODE unspecified)"
  else
    printf 'compose_env: missing\n'
    printf 'license_mode: unavailable\n'
  fi
  printf 'compose_env_content: not collected\n'

  section "Host"
  run_read_only "Kernel" uname -a
  run_read_only "Uptime" uptime
  run_read_only "Memory" free -h
  run_read_only "Repository filesystem" df -h "$ROOT"

  section "Docker"
  run_read_only "Docker Compose version" docker compose version
  run_read_only "Docker version" docker version --format 'client={{.Client.Version}} server={{.Server.Version}}'
  run_read_only "Docker capacity" docker system df
  run_read_only "Coomia containers" docker ps -a --filter name=coomia- --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
  run_read_only "Coomia volumes" docker volume ls --filter name=coomia- --format '{{.Name}}'

  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    section "Container Health Details"
    container_ids="$(docker ps -aq --filter name=coomia- 2>/dev/null || true)"
    if [[ -z "$container_ids" ]]; then
      echo 'no Coomia containers found'
    else
      while IFS= read -r container_id; do
        [[ -n "$container_id" ]] || continue
        docker inspect --format \
          'name={{.Name}} image_id={{.Image}} state={{.State.Status}} restart_count={{.RestartCount}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' \
          "$container_id" 2>&1 || printf '[inspect failed: %s]\n' "$container_id"
      done <<< "$container_ids"
    fi
  fi

  section "HTTP Health"
  if command -v curl >/dev/null 2>&1; then
    api_code="$(http_status "http://127.0.0.1:$api_port/health")"
    ui_code="$(http_status "http://127.0.0.1:$ui_port/")"
    printf 'api_http_status: %s\n' "$api_code"
    printf 'ui_http_status: %s\n' "$ui_code"
  else
    echo 'curl: unavailable'
  fi

  section "Deployment File Integrity"
  if command -v sha256sum >/dev/null 2>&1; then
    find "$ROOT/compose" "$ROOT/kubernetes" "$ROOT/scripts" -type f \
      \( -name '*.yml' -o -name '*.yaml' -o -name '*.sh' -o -name '*.conf' \) \
      -print0 | sort -z | xargs -0 sha256sum 2>&1 || echo '[checksum collection failed]'
  else
    echo 'sha256sum: unavailable'
  fi

  section "Sharing Notice"
  echo 'Review this report before external transfer. It may contain hostnames, ports, paths, container identifiers, and infrastructure metadata.'
  echo 'Application logs and secret values were intentionally excluded.'
} > "$output_file"

printf 'diagnostic report created: %s\n' "$output_file"
