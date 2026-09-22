#!/usr/bin/env bash
# Abre o laboratório de forma clara: sobe o Redis e 4 janelas
# (cliente + 3 Sentinels). Rode no terminal do Ubuntu:
#
#   cd ~/Documentos/projetos/academicos/redis
#   ./scripts/apresentacao.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"

abrir_janela() {
  local titulo="$1"
  local alvo="$2"
  local cmd="$ROOT/scripts/cli.sh $alvo"

  if command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal --title="$titulo" --working-directory="$ROOT" -- bash -c "$cmd; echo; echo 'Janela encerrada. Enter fecha.'; read" &
    return
  fi
  if command -v kgx >/dev/null 2>&1; then
    kgx --title="$titulo" -- bash -c "cd '$ROOT' && $cmd; read" &
    return
  fi
  if command -v x-terminal-emulator >/dev/null 2>&1; then
    x-terminal-emulator -T "$titulo" -e bash -c "cd '$ROOT' && $cmd; read" &
    return
  fi
  return 1
}

cat <<'EOF'

========================================
  Laboratório Redis — apresentação
========================================

EOF

echo "==> Subindo master, réplica, 3 Sentinels e o cliente..."
if ! docker info >/dev/null 2>&1; then
  echo
  echo "    Docker ainda pede sudo em cada janela."
  echo "    Para não pedir mais, rode UMA vez (e depois saia da conta do Ubuntu):"
  echo "      ./scripts/setup-docker.sh"
  echo
fi
compose up -d --wait
echo "    Stack no ar."
echo

echo "==> Abrindo 4 janelas..."
if abrir_janela "1 · Cliente (master)" master \
  && abrir_janela "2 · Sentinel 1" sentinel-1 \
  && abrir_janela "3 · Sentinel 2" sentinel-2 \
  && abrir_janela "4 · Sentinel 3" sentinel-3; then
  sleep 1
  echo "    Quatro janelas abertas."
else
  echo "    Não achei terminal gráfico. Abra 4 janelas na mão e rode:"
  echo "      ./scripts/cli.sh master"
  echo "      ./scripts/cli.sh sentinel-1"
  echo "      ./scripts/cli.sh sentinel-2"
  echo "      ./scripts/cli.sh sentinel-3"
fi

# Este terminal fica como roteiro + failover.
cat <<'EOF'

----------------------------------------
  O QUE DIGITAR EM CADA JANELA
----------------------------------------

JANELA 1 — Cliente (prompt redis-master:6379>)
    SET nome Thomaz
    GET nome

JANELA 2, 3 e 4 — Sentinels (prompt sentinel-N:26379>)
    PING
    SENTINEL get-master-addr-by-name mymaster

    Os três devem responder:  redis-master

----------------------------------------
  FAILOVER  (neste terminal, aqui embaixo)
----------------------------------------

    sudo docker stop redis-master

    Nos Sentinels o master vira:  redis-replica

    Na janela 1 o cliente perde o master.
    Conecte na réplica promovida:

    ./scripts/cli.sh replica
    SET aula:depois 1
    GET aula:depois

    Religar o nó antigo (volta como réplica):
    sudo docker start redis-master

----------------------------------------
  ENCERRAR
----------------------------------------

    sudo docker compose down -v

EOF
