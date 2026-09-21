#!/usr/bin/env bash
# Demo automática da apresentação (um terminal só).
# Sem janelas extras → não pede senha em cada uma.
# Pausa entre os passos para dá tempo de acompanhar.
#
#   ./scripts/demo-ao-vivo.sh
#   PAUSA=3 ./scripts/demo-ao-vivo.sh          # mais rápido
#   PAUSA=enter ./scripts/demo-ao-vivo.sh      # espera Enter
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Autentica sudo UMA vez neste terminal, se o Docker ainda exigir.
if docker info >/dev/null 2>&1; then
  DOCKER=(docker)
else
  echo
  echo "Docker ainda precisa de sudo. Confirme senha/digital UMA vez."
  echo "(Para nunca mais pedir: ./scripts/setup-docker.sh e depois saia da conta do Ubuntu.)"
  echo
  sudo -v
  DOCKER=(sudo docker)
fi

# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"

PAUSA="${PAUSA:-6}"

passo() {
  echo
  echo "============================================================"
  echo "  $1"
  echo "============================================================"
}

pausar() {
  if [[ "$PAUSA" == "enter" ]]; then
    echo
    read -r -p "    [Enter] para o próximo passo..."
  else
    echo
    echo "    … ${PAUSA}s para dar tempo de ler …"
    sleep "$PAUSA"
  fi
}

mostrar() {
  local titulo="$1"
  shift
  echo
  echo "    $titulo"
  echo "    ----------------------------------------"
  cli "$@" | sed 's/^/    /'
}

passo "1/6  Subindo o laboratório"
cleanup_lab
compose up -d --wait
echo "    master + réplica + 3 Sentinels no ar."
pausar

passo "2/6  Quem é o master (os 3 Sentinels)"
wait_for_master
for s in sentinel-1 sentinel-2 sentinel-3; do
  addr="$(cli -h "$s" -p 26379 SENTINEL get-master-addr-by-name mymaster | tr '\n' ' ')"
  echo "    $s  →  $addr"
done
pausar

passo "3/6  Replicação: grava no master, lê na réplica"
echo "    SET nome Thomaz     (no redis-master)"
cli -h redis-master SET nome Thomaz
echo "    SET tema redis-lab  (no redis-master)"
cli -h redis-master SET tema redis-lab
echo
echo -n "    GET nome no MASTER  = "
cli -h redis-master GET nome
echo -n "    GET nome na RÉPLICA = "
cli -h redis-replica GET nome
echo
echo "    Papéis agora:"
for host in redis-master redis-replica; do
  role="$(cli -h "$host" INFO replication | awk -F: '/^role:/{print $2}' | tr -d '\r')"
  echo "      $host → $role"
done
echo
echo "    O mesmo dado nas duas instâncias = replicação ok."
pausar

passo "4/6  Falha do master (docker stop redis-master)"
echo "    Derrubando redis-master..."
"${DOCKER[@]}" stop redis-master >/dev/null
echo "    Container parado. Sentinel tem ~5–15s para promover a réplica."
echo

NEW=""
for i in $(seq 1 30); do
  candidate="$(master_ip 2>/dev/null || true)"
  echo "    ${i}s  Sentinel aponta: ${candidate:-?}"
  if [[ "$candidate" == "redis-replica" ]]; then
    if cli -h redis-replica PING 2>/dev/null | grep -q PONG; then
      NEW=redis-replica
      break
    fi
  fi
  sleep 1
done

if [[ -z "$NEW" ]]; then
  echo "FAIL: failover não aconteceu a tempo." >&2
  "${DOCKER[@]}" start redis-master >/dev/null 2>&1 || true
  exit 1
fi

echo
echo "    Failover ok: o novo master é redis-replica."
pausar

passo "5/6  Continuidade do serviço na réplica promovida"
echo -n "    Dado antigo (nome)  = "
cli -h redis-replica GET nome
echo "    SET depois failover  (escrita no novo master)"
cli -h redis-replica SET depois "serviço-continuou"
echo -n "    GET depois          = "
cli -h redis-replica GET depois
echo
echo "    Serviço continuou: leitura antiga + escrita nova."
pausar

passo "6/6  Nó antigo volta como réplica"
"${DOCKER[@]}" start redis-master >/dev/null
echo "    redis-master religado. Aguardando o Sentinel rebaixar a réplica..."
for i in $(seq 1 20); do
  role="$(cli -h redis-master INFO replication 2>/dev/null | awk -F: '/^role:/{print $2}' | tr -d '\r' || true)"
  echo "    ${i}s  redis-master → ${role:-?}"
  if [[ "$role" == "slave" ]]; then
    break
  fi
  sleep 1
done

echo
echo "    Papel final:"
for host in redis-master redis-replica; do
  role="$(cli -h "$host" INFO replication | awk -F: '/^role:/{print $2}' | tr -d '\r')"
  echo "      $host → $role"
done
echo -n "    Master segundo o Sentinel: "
master_ip
echo
echo "    redis-replica = master   |   redis-master = réplica (cópia)"
pausar

echo
echo "============================================================"
echo "  Fim da demo — os dois cenários do roteiro passaram."
echo "============================================================"
echo
echo "  Stack continua no ar para inspeção."
echo "  Encerrar:  ${DOCKER[*]} compose down -v"
echo
echo "  Repetir do zero:  ./scripts/demo-ao-vivo.sh"
echo
