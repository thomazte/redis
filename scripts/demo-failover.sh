#!/usr/bin/env bash
# Cenário 2: falha do nó principal e continuidade via réplica (Sentinel).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"

echo "==> Estado inicial"
wait_for_master
OLD_MASTER="$(master_ip)"
OLD_CONTAINER="$(container_for_addr "$OLD_MASTER")"
echo "    Master atual: $OLD_MASTER ($OLD_CONTAINER)"

if [[ -z "$OLD_CONTAINER" ]]; then
  echo "FAIL: não reconheci o container do master ($OLD_MASTER)." >&2
  exit 1
fi

cli -h "$OLD_MASTER" SET aula:antes-falha "escrito-no-master-original"
echo "    chave aula:antes-falha gravada"

echo
echo "==> Derrubando o master ($OLD_CONTAINER)..."
"${DOCKER[@]}" stop "$OLD_CONTAINER" >/dev/null

echo "    Container parado. Aguardando o Sentinel promover a réplica (~5-15s)..."
NEW_MASTER=""
for i in $(seq 1 30); do
  sleep 1
  candidate="$(master_ip 2>/dev/null || true)"
  if [[ -n "$candidate" && "$candidate" != "$OLD_MASTER" ]]; then
    if cli -h "$candidate" PING 2>/dev/null | grep -q PONG; then
      NEW_MASTER="$candidate"
      break
    fi
  fi
  echo "    ... ainda esperando ($i/30) (sentinel=$candidate)"
done

if [[ -z "$NEW_MASTER" ]]; then
  echo "FAIL: o Sentinel não promoveu outro master a tempo." >&2
  echo "Subindo o container parado de volta para não deixar o lab quebrado..."
  "${DOCKER[@]}" start redis-master redis-replica >/dev/null 2>&1 || true
  exit 1
fi

echo
echo "==> Failover concluído"
echo "    Novo master: $NEW_MASTER"

echo
echo "==> Continuidade: leitura do dado antigo no novo master"
echo -n "    aula:antes-falha = "
cli -h "$NEW_MASTER" GET aula:antes-falha

echo
echo "==> Continuidade: nova escrita no master promovido"
cli -h "$NEW_MASTER" SET aula:depois-falha "escrito-depois-do-failover"
echo -n "    aula:depois-falha = "
cli -h "$NEW_MASTER" GET aula:depois-falha

echo
echo "==> Religando o nó que caiu (deve voltar como RÉPLICA)"
"${DOCKER[@]}" start "$OLD_CONTAINER" >/dev/null
RECOVERED="$OLD_MASTER"

echo "    Aguardando $RECOVERED aceitar PING..."
for i in $(seq 1 20); do
  if cli -h "$RECOVERED" PING 2>/dev/null | grep -q PONG; then
    break
  fi
  sleep 1
done

echo "    Aguardando o Sentinel rebaixar $RECOVERED a réplica..."
for i in $(seq 1 20); do
  role="$(cli -h "$RECOVERED" INFO replication 2>/dev/null | awk -F: '/^role:/{print $2}' | tr -d '\r' || true)"
  if [[ "$role" == "slave" ]]; then
    break
  fi
  sleep 1
done

echo
echo "==> Papel final de cada nó"
for host in redis-master redis-replica; do
  role="$(cli -h "$host" INFO replication | awk -F: '/^role:/{print $2}' | tr -d '\r')"
  echo "    $host -> $role"
done

echo -n "    Master segundo o Sentinel: "
master_ip

echo
echo "Failover ok: o serviço continuou na réplica e o nó antigo voltou como cópia."
echo "Para voltar à topologia inicial (redis-master = master):"
echo "    ${DOCKER[*]} compose down -v && ${DOCKER[*]} compose up -d --wait"
