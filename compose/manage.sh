#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${COOMIA_ENV_FILE:-$SCRIPT_DIR/.env}"
RUNTIME_ENV_FILE="$SCRIPT_DIR/generated/runtime.env"
command_name="${1:-status}"
shift || true

[[ -f "$ENV_FILE" ]] || { echo "error: missing $ENV_FILE" >&2; exit 1; }
set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
if [[ -f "$RUNTIME_ENV_FILE" ]]; then . "$RUNTIME_ENV_FILE"; fi
set +a

files=(-f "$SCRIPT_DIR/docker-compose.yml" -f "$SCRIPT_DIR/docker-compose.app.yml")
if [[ "${LICENSE_MODE:-online}" == "offline" ]]; then files+=(-f "$SCRIPT_DIR/docker-compose.license-offline.yml"); fi
compose=(docker compose --env-file "$ENV_FILE" "${files[@]}")

case "$command_name" in
  start) exec bash "$ROOT/install.sh" compose ;;
  stop) "${compose[@]}" stop ;;
  down) "${compose[@]}" down ;;
  restart) "${compose[@]}" restart ;;
  restart-api) "${compose[@]}" restart platform-api ;;
  status) "${compose[@]}" ps ;;
  logs) "${compose[@]}" logs --tail "${LOG_TAIL:-200}" "$@" ;;
  config) "${compose[@]}" config --quiet; echo "configuration is valid" ;;
  health)
    curl -fsS "http://127.0.0.1:${PLATFORM_API_PORT:-8050}/health"
    printf '\n'
    curl -fsS -o /dev/null "http://127.0.0.1:${PLATFORM_UI_PORT:-3000}/"
    echo "UI: healthy"
    ;;
  *)
    echo "usage: $0 {start|stop|down|restart|restart-api|status|logs|config|health}" >&2
    exit 2
    ;;
esac
