#!/bin/bash
# Cria (ou promove) um SUPER ADMIN (Master Admin) do Fluxo Email MKT.
# É quem gerencia as empresas, valida KYB e tem acesso global.
#
# Uso: ./scripts/create_admin.sh EMAIL SENHA
# Exemplo: ./scripts/create_admin.sh admin@fluxodigitaltech.com.br MinhaSenh@Forte123
#
# Idempotente: se o usuário já existir, apenas concede o papel de admin.

EMAIL="${1:-}"
PASSWORD="${2:-}"

if [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
  echo "Uso: $0 EMAIL SENHA"
  exit 1
fi

CONTAINER="fluxo-emailmkt-app"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "Container '${CONTAINER}' não está rodando."
  echo "Inicie com: docker compose -f docker-compose.prod.yml up -d"
  exit 1
fi

echo "Criando/promovendo super admin: ${EMAIL} ..."

docker exec "$CONTAINER" bin/keila eval "Keila.ReleaseTasks.create_admin(\"${EMAIL}\", \"${PASSWORD}\")"
