#!/usr/bin/env bash
set -uo pipefail

mode="${1:-compose}"
root="${2:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
failures=0
warnings=0

pass() { printf '[PASS] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; warnings=$((warnings + 1)); }
fail() { printf '[FAIL] %s\n' "$*"; failures=$((failures + 1)); }
check_command() { command -v "$1" >/dev/null 2>&1 && pass "command available: $1" || fail "missing command: $1"; }

[[ "$mode" == "compose" || "$mode" == "kubernetes" ]] || {
  echo "usage: $0 [compose|kubernetes] [repository-root]" >&2
  exit 2
}

echo "Coomia AI Data Platform preflight"
echo "mode: $mode"
echo "timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

[[ "$(uname -s)" == "Linux" ]] && pass "Linux host" || fail "Linux is required"
case "$(uname -m)" in
  x86_64|amd64) pass "architecture: amd64" ;;
  *) fail "unsupported architecture: $(uname -m); this release requires amd64" ;;
esac

for cmd in bash realpath stat sed awk grep sha256sum openssl curl; do check_command "$cmd"; done

if [[ "$mode" == "compose" ]]; then
  check_command docker
  docker info >/dev/null 2>&1 && pass "Docker daemon is reachable" || fail "Docker daemon is not reachable"
  docker compose version >/dev/null 2>&1 && pass "Docker Compose v2 is available" || fail "Docker Compose v2 is unavailable"
  [[ -S /var/run/docker.sock ]] && pass "Docker socket exists" || warn "Docker socket is not at /var/run/docker.sock"

  memory_kib="$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
  (( memory_kib >= 16 * 1024 * 1024 )) && pass "memory is at least 16 GiB" || warn "less than 16 GiB RAM detected"
  cpu_count="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 0)"
  (( cpu_count >= 8 )) && pass "CPU count is at least 8" || warn "fewer than 8 CPU cores detected"
  free_kib="$(df -Pk "$root" | awk 'NR==2 {print $4}')"
  (( free_kib >= 50 * 1024 * 1024 )) && pass "at least 50 GiB free disk" || warn "less than 50 GiB free disk detected"

  required=(
    compose/docker-compose.yml compose/docker-compose.app.yml compose/docker-compose.license-offline.yml
    compose/install.sh compose/manage.sh compose/.env.example compose/config/postgres/init.sh
    scripts/init-config.sh
  )
else
  check_command kubectl
  check_command envsubst
  kubectl cluster-info >/dev/null 2>&1 && pass "Kubernetes API is reachable" || fail "Kubernetes API is not reachable"
  required=(kubernetes/install.sh kubernetes/10-platform-api.yaml kubernetes/mds-flink-namespace.yaml)
fi

for file in "${required[@]}"; do
  [[ -f "$root/$file" ]] && pass "file exists: $file" || fail "file missing: $file"
done

echo "result: failures=$failures warnings=$warnings"
(( failures == 0 )) || exit 1
