#!/bin/bash
# Cria um novo usuário no Fluxo Email MKT
# Uso: ./scripts/create_user.sh EMAIL SENHA
# Exemplo: ./scripts/create_user.sh usuario@email.com MinhaSenh@123

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

echo "Criando usuário: ${EMAIL} ..."

docker exec "$CONTAINER" bin/keila eval "
  case Keila.Auth.create_user(
    %{email: \"${EMAIL}\", password: \"${PASSWORD}\"},
    skip_activation_email: true
  ) do
    {:ok, user} ->
      Keila.Auth.activate_user(user.id)
      IO.puts(\"✓ Usuário criado e ativado: #{user.email}\")
    {:error, changeset} ->
      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, \"%{#{k}}\", to_string(v)) end)
      end)
      IO.puts(\"✗ Erro: #{inspect(errors)}\")
  end
"
