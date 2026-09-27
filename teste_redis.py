import redis
import time

IP_MASTER = "192.168.50.10"
IP_REPLICA= "192.168.50.20"
PORTA = 6379

print("=== 1. TESTE DE ESCRITA NO MASTER ===")
try:
    master = redis.Redis(host=IP_MASTER, port=PORTA, decode_responses=True, socket_timeout=3)
    master.set("disciplina", "Sistemas Distribuidos")
    print(f"[Master] Chave 'disciplina' gravada: {master.get('disciplina')}")
except Exception as e:
    print(f"[Master] Erro: {e}")

time.sleep(0.5)

print("\n=== 2. TESTE DE LEITURA NA REPLICA ===")
try:
    replica = redis.Redis(host=IP_REPLICA, port=PORTA, decode_responses=True, socket_timeout=3)
    valor = replica.get("disciplina")
    print(f"[Replica] Chave lida com sucesso: {valor}")
except Exception as e:
    print(f"[Replica] Erro: {e}")

print("\n=== 3. TENTATIVA DE ESCRITA NA REPLICA ===")
try:
   replica.set("chave_invalida", "teste")
except redis.exceptions.ReadOnlyError:
    print("[Replica] Operacao rejeitada: Replica configurada como Read-Only.")
except Exception as e:
    print(f"[Replica] Outro erro: {e}")

print("\n=== 4. SIMULANDO FAILOVER ===")
try:
   replica.execute_command("REPLICAOF", "NO", "ONE")
   time.sleep(1)

   info = replica.info("replication")
   print(f"[Failover] Novo papel do no 192.168.50.20: {info.get('role')}")
except Exception as e:
    print(f"[Failover] Erro ao promover replica: {e}")

print("\n=== 5. TESTE DE ESCRITA NO NOVO MASTER ===")
try:
   replica.set("status_failover", "Escrita liberada apos promocao")
   resultado = replica.get("status_failover")
   print(f"[Novo Master] Sucesso! VAlor gravado: '{resultado}'")
except Exception as e:
    print(f"[Novo Master] Falha na escrita: {e}")

print("\n=== 6. RESTAURANDO TOPOLOGIA ORIGINAL ===")
try:
   replica.execute_command("REPLICAOF", IP_MASTER, PORTA)
   time.sleep(0.5)
   info_restaurada = replica.info("replication")
   print(f"[Restauracao] Papel redefinido para: {info_restaurada.get('role')}")
except Exception as e:
    print(f"[Restauracao] Erro ao redefinir replica: {e}")
