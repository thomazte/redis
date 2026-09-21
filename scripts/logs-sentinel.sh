#!/usr/bin/env bash
# Acompanha o log de um Sentinel (1, 2 ou 3).
#   ./scripts/logs-sentinel.sh
#   ./scripts/logs-sentinel.sh 2
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"

n="${1:-1}"
case "$n" in
  1|2|3) ;;
  *)
    echo "Uso: $0 {1|2|3}" >&2
    exit 1
    ;;
esac

echo "Log do Sentinel $n. Ctrl+C para sair."
echo "No failover procure: +sdown  +odown  +switch-master"
exec "${DOCKER[@]}" logs -f "redis-sentinel-$n"
