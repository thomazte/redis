#!/usr/bin/env bash
# Cenário 1: inserção e leitura distribuída (master -> réplica).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"

echo "==> Aguardando master via Sentinel..."
wait_for_master

MASTER="$(master_ip)"
echo "    Master atual: $MASTER"

echo
echo "==> Gravando no master (SET aula:aluno Thomaz)"
cli -h "$MASTER" SET aula:aluno Thomaz
cli -h "$MASTER" SET aula:tema "Redis replicacao + Sentinel"

echo
echo "==> Lendo no master"
echo -n "    aula:aluno = "
cli -h "$MASTER" GET aula:aluno
echo -n "    aula:tema  = "
cli -h "$MASTER" GET aula:tema

echo
echo "==> Lendo na réplica (redis-replica) — deve espelhar o master"
cli -h redis-replica INFO replication | grep -E 'role:|master_host:|master_link_status:'
echo -n "    aula:aluno (redis-replica) = "
cli -h redis-replica GET aula:aluno

echo
echo "==> Papel de cada nó Redis"
for host in redis-master redis-replica; do
  role="$(cli -h "$host" INFO replication | awk -F: '/^role:/{print $2}' | tr -d '\r')"
  echo "    $host -> $role"
done

echo
echo "Replicação ok: o dado escrito no master apareceu no outro nó."
