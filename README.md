# Replicação Master-Replica com Redis

Prática de Sistemas Distribuídos: cluster Redis com um master e uma réplica em duas VMs (Ubuntu Server 26.04 no VirtualBox). O detalhamento está no relatório.

**Autores:** Thomaz Arthur e Lucas Gabriel

## O que tem aqui

| Caminho | Conteúdo |
| --- | --- |
| `sistemas-distribuidos/docs/Relatório Prático.pdf` | Relatório da prática |
| `apresentacao/` | Site da apresentação |
| `teste_redis.py` | Validação do cluster via `python3-redis` |

## Apresentação

Abra `apresentacao/index.html` no navegador. As setas do teclado trocam de seção.

## Script

O script espera o cluster no ar: master em `192.168.50.10` e réplica em `192.168.50.20`, porta `6379`.

```bash
python3 teste_redis.py
```
