#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
mode="${1:-compose}"
shift || true

case "$mode" in
  compose)
    bash "$SCRIPT_DIR/scripts/preflight-linux.sh" compose "$SCRIPT_DIR"
    exec bash "$SCRIPT_DIR/compose/install.sh" "$@"
    ;;
  kubernetes)
    bash "$SCRIPT_DIR/scripts/preflight-linux.sh" kubernetes "$SCRIPT_DIR"
    exec bash "$SCRIPT_DIR/kubernetes/install.sh" "$@"
    ;;
  -h|--help|help)
    echo "usage: $0 [compose|kubernetes]"
    ;;
  *)
    echo "error: unsupported installation mode: $mode" >&2
    echo "usage: $0 [compose|kubernetes]" >&2
    exit 2
    ;;
esac
