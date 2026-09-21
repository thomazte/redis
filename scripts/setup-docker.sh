#!/usr/bin/env bash
# Libera o Docker SEM senha nas próximas sessões.
# Não grava a senha em arquivo (isso vazaria no trabalho da disciplina).
#
# Rode UMA vez:
#   ./scripts/setup-docker.sh
# Depois saia da conta do Ubuntu e entre de novo (não basta fechar o terminal).
set -euo pipefail

if docker info >/dev/null 2>&1; then
  echo "Já está ok: o Docker funciona sem sudo neste terminal."
  exit 0
fi

echo "Vai pedir senha/digital UMA vez, só para te colocar no grupo docker."
sudo usermod -aG docker "$USER"

cat <<EOF

Pronto. O grupo docker só vale depois de uma sessão nova.

1. Feche os programas (Cursor, terminais).
2. No Ubuntu: clique no usuário (canto superior direito) → Sair / Log out.
3. Entre de novo.
4. Abra um terminal e rode:

   cd ~/Documentos/projetos/academicos/redis
   ./scripts/apresentacao.sh

Não deve mais pedir senha.

EOF
