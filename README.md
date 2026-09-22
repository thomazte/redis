# Laboratório Redis — replicação + Sentinel

Grupo 4 da disciplina de Sistemas Distribuídos. O roteiro aceita **replicação ou cluster**; este laboratório implementa **replicação master/réplica com Redis Sentinel** para failover automático.

Isto **não** é Redis Cluster (modo cluster com hash slots). É um master, uma réplica e três Sentinels na mesma rede Docker.

## Arquitetura

```
                    ┌─────────────┐
                    │  Sentinel 1 │ 172.28.56.31 :26379
                    │  Sentinel 2 │ 172.28.56.32 :26379
                    │  Sentinel 3 │ 172.28.56.33 :26379
                    └──────┬──────┘
                           │ monitora / promove
              ┌────────────┴────────────┐
              ▼                         ▼
     redis-master                redis-replica
     172.28.56.10:6379          172.28.56.20:6379
     (escrita + leitura)         (cópia, só leitura)
              │                         │
              └──────── replicação ─────┘
```

O cliente de demonstração (`redis-cli`) fica em `172.28.56.40` e fala com os nós pelos IPs da rede `redelocal`.

A faixa `192.168.56.0/24` (Host-Only típico do VirtualBox) não é usada: o Docker recusa criar um pool que já exista na máquina. Por isso o laboratório usa `172.28.56.0/24`.

## Por que Docker e Sentinel

A primeira tentativa foi um conjunto de VMs no VirtualBox (clones Redis2/Redis3, rede Host-Only). Os clones **falharam no boot** (mídia de boot ausente ou mal configurada) e o ambiente ficou pesado demais para testar a tempo da entrega. O relato, o print e o que o log mostra estão no anexo [Problemas com o VirtualBox](docs/problemas-virtualbox.md) — separado de propósito, para este README continuar sendo só o laboratório que a turma replica.

- Docker no lugar do VirtualBox: mesmo desenho de vários nós, bem mais leve e reproduzível.
- Só master + réplica **não** garante continuidade: se o master cai, a réplica continua somente leitura.
- O Sentinel observa o master, promove a réplica e avisa quem é o novo master. Isso cobre o cenário obrigatório de falha do nó principal.

## Pré-requisitos

- Docker Engine + Docker Compose v2
- Permissão para usar o Docker (usuário no grupo `docker`, ou `sudo`)

Se aparecer `permission denied` em `/var/run/docker.sock`, **não coloque a senha no script**. Rode uma vez:

```bash
./scripts/setup-docker.sh
```

Saia da conta do Ubuntu e entre de novo. Depois os scripts sobem sem senha.

## Apresentação automática (recomendado)

Um terminal só, testes do roteiro com pausa para acompanhar. Senha no máximo **uma vez** neste terminal (não abre janelas extras):

```bash
cd ~/Documentos/projetos/academicos/redis
./scripts/demo-ao-vivo.sh
```

Mais rápido: `PAUSA=3 ./scripts/demo-ao-vivo.sh`  
Passo a passo no Enter: `PAUSA=enter ./scripts/demo-ao-vivo.sh`

## Site da apresentação

Slides em tela cheia, GSAP no scroll, **sem barra de rolagem visível**. Na pasta do projeto:

```bash
cd ~/Documentos/projetos/academicos/redis/site
python3 -m http.server 8765
```

Abra [http://127.0.0.1:8765](http://127.0.0.1:8765). Role a roda ou use ↑ ↓. Os pontos à direita saltam de seção.


## Subir o laboratório

```bash
sudo docker compose up -d --wait
```

Conferir:

```bash
sudo docker compose ps
sudo docker compose exec redis-cli redis-cli -h redis-master PING
sudo docker compose exec redis-cli redis-cli -h sentinel-1 -p 26379 SENTINEL get-master-addr-by-name mymaster
```

## Demo em três terminais

### No terminal do Ubuntu

1. `Ctrl+Alt+T` abre o primeiro terminal.
2. `Ctrl+Shift+N` abre outra **janela** (melhor na apresentação, lado a lado). Ou `Ctrl+Shift+T` para outra **aba**.
3. Repita para o terceiro.

Nos três:

```bash
cd ~/Documentos/projetos/academicos/redis
```

Só no primeiro, uma vez:

```bash
sudo docker compose up -d --wait
```

Depois, um comando em cada janela:

```bash
./scripts/cli.sh master
```

```bash
./scripts/cli.sh replica-monitor
```

```bash
./scripts/watch-sentinel.sh
```

No master: `SET nome Thomaz`. Na réplica o `SET` aparece; no Sentinel continua `redis-master`.

Failover: numa quarta janela (ou pare o `watch` com Ctrl+C no terminal 3):

```bash
./scripts/logs-sentinel.sh
```

E em outro:

```bash
sudo docker stop redis-master
```

Encerrar o laboratório (qualquer terminal, na pasta do projeto):

```bash
sudo docker compose down -v
```

### Sentinels e cliente em terminais separados

Um comando só no terminal:

```bash
cd ~/Documentos/projetos/academicos/redis
./scripts/apresentacao.sh
```

Sobe o stack, abre 4 janelas (cliente + 3 Sentinels) e deixa o roteiro neste terminal. Se pedir sudo/digital, confirme.

| Janela | Comando |
|---|---|
| Cliente | `./scripts/cli.sh master` |
| Sentinel 1 | `./scripts/cli.sh sentinel-1` |
| Sentinel 2 | `./scripts/cli.sh sentinel-2` |
| Sentinel 3 | `./scripts/cli.sh sentinel-3` |

No **cliente** (prompt `redis-master:6379>`):

```text
SET nome Thomaz
GET nome
```

Em **qualquer Sentinel** (prompt `sentinel-1:26379>` etc.):

```text
PING
SENTINEL get-master-addr-by-name mymaster
SENTINEL sentinels mymaster
SENTINEL replicas mymaster
```

Os três devem devolver o mesmo master. No failover (`sudo docker stop redis-master` numa 5ª janela) os três passam a apontar para `redis-replica`.

Para ver o log de cada Sentinel (em vez do `redis-cli`):

```bash
./scripts/logs-sentinel.sh 1
./scripts/logs-sentinel.sh 2
./scripts/logs-sentinel.sh 3
```

O painel do Sentinel passa a mostrar `redis-replica`. Depois:

```bash
./scripts/cli.sh replica
SET aula:depois 1
```

A réplica promovida aceita escrita. Religar o nó antigo:

```bash
sudo docker start redis-master
./scripts/cli.sh master
INFO replication
```

Deve mostrar `role:slave`. Prompt interativo do Sentinel: `./scripts/cli.sh sentinel`.

Para voltar à topologia inicial:

```bash
sudo docker compose down -v && sudo docker compose up -d --wait
```

## Demos (cenários obrigatórios)

Tudo de uma vez:

```bash
./scripts/demo.sh
```

Ou por partes, com o stack já no ar:

```bash
./scripts/demo-replicacao.sh   # inserção e leitura na réplica
./scripts/demo-failover.sh     # para o master e mostra continuidade
```

Depois do failover a topologia inverte (o nó `.20` vira master). Para voltar ao estado inicial:

```bash
sudo docker compose down -v
sudo docker compose up -d --wait
```

## Comandos manuais úteis

Gravar no master e ler na réplica:

```bash
sudo docker compose exec redis-cli redis-cli -h redis-master SET aula:teste 1
sudo docker compose exec redis-cli redis-cli -h redis-replica GET aula:teste
```

Ver papéis:

```bash
sudo docker compose exec redis-cli redis-cli -h redis-master INFO replication
sudo docker compose exec redis-cli redis-cli -h redis-replica INFO replication
```

Simular a falha na mão:

```bash
sudo docker stop redis-master
sudo docker compose exec redis-cli redis-cli -h sentinel-1 -p 26379 SENTINEL get-master-addr-by-name mymaster
```

## Portas no host

| Serviço    | IP Docker       | Porta no host |
|------------|-----------------|---------------|
| master     | 172.28.56.10   | 6379          |
| réplica    | 172.28.56.20   | 6380          |
| sentinel-1 | 172.28.56.31   | 26379         |
| sentinel-2 | 172.28.56.32   | 26380         |
| sentinel-3 | 172.28.56.33   | 26381         |

Do host, `localhost:6379` fala com o container `redis-master`, mesmo depois de um failover (o papel Redis pode ter mudado). Para a demo de HA, use o container `redis-cli` e o endereço que o Sentinel devolver.

## Conceitos cobertos

- **Replicação:** a réplica aplica as mesmas escritas do master (cópia assíncrona).
- **Consistência:** modelo eventualmente consistente; há um atraso curto até a réplica refletir o `SET`.
- **Alta disponibilidade:** o Sentinel promove a réplica se o master ficar inalcançável por 5s (quórum 2 de 3).
- **Cache distribuído:** Redis como armazenamento em memória compartilhado entre nós.

## Encerrar

```bash
sudo docker compose down
```

Apaga também os dados persistidos (AOF):

```bash
sudo docker compose down -v
```
