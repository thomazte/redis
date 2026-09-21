#!/usr/bin/env bash
# Helpers para falar com o Redis de dentro da rede Docker.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -z "${DOCKER+x}" ]] || [[ ${#DOCKER[@]} -eq 0 ]]; then
  if docker info >/dev/null 2>&1; then
    DOCKER=(docker)
  else
    DOCKER=(sudo docker)
  fi
fi

compose() {
  "${DOCKER[@]}" compose "$@"
}

CONTAINERS=(
  redis-master
  redis-replica
  redis-cli
  redis-sentinel-1
  redis-sentinel-2
  redis-sentinel-3
)

cleanup_lab() {
  compose down --remove-orphans >/dev/null 2>&1 || true
  local c
  for c in "${CONTAINERS[@]}"; do
    "${DOCKER[@]}" rm -f "$c" >/dev/null 2>&1 || true
  done
}

# docker exec no container redis-cli (mesma rede) usa DNS: sentinel-1, redis-master.
# --raw: SENTINEL get-master-addr-by-name devolve IP/hostname e porta em linhas separadas.
cli() {
  "${DOCKER[@]}" exec redis-cli redis-cli --raw "$@"
}

SENTINEL_HOST=sentinel-1
SENTINEL_PORT=26379

master_addr() {
  cli -h "$SENTINEL_HOST" -p "$SENTINEL_PORT" SENTINEL get-master-addr-by-name mymaster
}

master_ip() {
  master_addr | awk 'NR==1 {print $1}'
}

master_port() {
  master_addr | awk 'NR==2 {print $1}'
}

container_for_addr() {
  case "$1" in
    172.28.56.10|redis-master) echo redis-master ;;
    172.28.56.20|redis-replica) echo redis-replica ;;
    *) echo "" ;;
  esac
}

wait_for_master() {
  local tries=20
  local i ip port
  for i in $(seq 1 "$tries"); do
    ip="$(master_ip 2>/dev/null || true)"
    port="$(master_port 2>/dev/null || true)"
    if [[ -n "$ip" && "$ip" != "(nil)" && -n "$port" ]]; then
      if cli -h "$ip" -p "$port" PING 2>/dev/null | grep -q PONG; then
        echo "    master atual: $ip:$port"
        return 0
      fi
    fi
    echo "    tentativa $i/$tries (Sentinel ainda não apontou um master saudável)"
    sleep 1
  done
  echo "Timeout esperando o Sentinel. Diagnóstico:" >&2
  echo "--- PING sentinel-1 ---" >&2
  cli -h sentinel-1 -p 26379 PING >&2 || true
  echo "--- SENTINEL masters ---" >&2
  cli -h sentinel-1 -p 26379 SENTINEL masters >&2 || true
  echo "--- PING redis-master ---" >&2
  cli -h redis-master PING >&2 || true
  echo "--- logs sentinel-1 ---" >&2
  "${DOCKER[@]}" logs --tail 30 redis-sentinel-1 >&2 || true
  return 1
}
