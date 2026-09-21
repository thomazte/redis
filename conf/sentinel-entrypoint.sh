#!/bin/sh
set -e

# Copia a config para um arquivo gravável. O Sentinel precisa poder
# atualizar o endereço do master depois de um failover.
cp /sentinel-base.conf /tmp/sentinel.conf

# Cada Sentinel anuncia o próprio IP da rede Docker (não o hostname interno).
if [ -n "$ANNOUNCE_IP" ]; then
  echo "sentinel announce-ip $ANNOUNCE_IP" >> /tmp/sentinel.conf
  echo "sentinel announce-port 26379" >> /tmp/sentinel.conf
fi

exec redis-sentinel /tmp/sentinel.conf
