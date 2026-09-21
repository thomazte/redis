#!/usr/bin/env bash
# Atualiza a cada 2s quem o Sentinel considera master (bom no 3º terminal).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"

echo "Painel do Sentinel. Ctrl+C para sair."
sleep 1

while true; do
  addr="$(master_addr 2>/dev/null || true)"
  ip="$(printf '%s\n' "$addr" | awk 'NR==1 {print $1}')"
  port="$(printf '%s\n' "$addr" | awk 'NR==2 {print $1}')"
  quorum="$(cli -h sentinel-1 -p 26379 SENTINEL ckquorum mymaster 2>/dev/null || echo '(indisponível)')"

  clear
  echo "========================================"
  echo "  Redis Sentinel  (mymaster)"
  echo "  $(date '+%H:%M:%S')"
  echo "========================================"
  echo
  echo "  Master atual : ${ip:-?} : ${port:-?}"
  echo "  Quórum       : $quorum"
  echo
  echo "  No failover este nome muda de"
  echo "  redis-master para redis-replica."
  echo
  echo "  Ctrl+C para sair."
  sleep 2
done
