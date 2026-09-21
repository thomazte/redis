#!/usr/bin/env bash
# Abre redis-cli interativo (um processo por terminal).
#
#   ./scripts/cli.sh master
#   ./scripts/cli.sh replica
#   ./scripts/cli.sh replica-monitor
#   ./scripts/cli.sh cliente            # shell do container cliente
#   ./scripts/cli.sh sentinel-1
#   ./scripts/cli.sh sentinel-2
#   ./scripts/cli.sh sentinel-3
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"

usage() {
  echo "Uso: $0 {master|replica|replica-monitor|cliente|sentinel-1|sentinel-2|sentinel-3}" >&2
  exit 1
}

open_sentinel() {
  local name="$1"
    echo "Quando aparecer ${name}:26379>  digite EXATAMENTE:"
    echo "  PING"
    echo "  SENTINEL get-master-addr-by-name mymaster"
  exec "${DOCKER[@]}" exec -it redis-cli redis-cli -h "$name" -p 26379
}

[[ $# -ge 1 ]] || usage

case "$1" in
  master)
    echo "Quando aparecer redis-master:6379>  digite EXATAMENTE:"
    echo "  SET nome Thomaz"
    echo "  GET nome"
    exec "${DOCKER[@]}" exec -it redis-cli redis-cli -h redis-master
    ;;
  replica)
    echo "Quando aparecer redis-replica:6379>  digite:"
    echo "  GET nome"
    exec "${DOCKER[@]}" exec -it redis-cli redis-cli -h redis-replica
    ;;
  replica-monitor)
    echo "MONITOR na réplica: cada SET no master aparece aqui."
    echo "Ctrl+C para sair."
    exec "${DOCKER[@]}" exec -it redis-cli redis-cli -h redis-replica MONITOR
    ;;
  cliente|client)
    echo "Container cliente (redis-cli). Exemplos:"
    echo "  redis-cli -h redis-master"
    echo "  redis-cli -h redis-replica"
    echo "  redis-cli -h sentinel-1 -p 26379"
    exec "${DOCKER[@]}" exec -it redis-cli sh
    ;;
  sentinel|sentinel-1)
    open_sentinel sentinel-1
    ;;
  sentinel-2)
    open_sentinel sentinel-2
    ;;
  sentinel-3)
    open_sentinel sentinel-3
    ;;
  *)
    usage
    ;;
esac
