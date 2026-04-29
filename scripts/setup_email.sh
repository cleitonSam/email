#!/bin/bash
# =============================================================================
# Fluxo Email MKT — Script de Configuração de Email
# =============================================================================
# Uso:
#   ./scripts/setup_email.sh <project_id> <nome_remetente> <email_remetente> \
#       <smtp_host> <smtp_port> <smtp_user> <smtp_pass> <tls_mode>
#
# Exemplo Gmail:
#   ./scripts/setup_email.sh "p_..." "Minha Empresa" "meu@gmail.com" \
#       "smtp.gmail.com" 465 "meu@gmail.com" "minha_senha_app" "tls"
#
# Exemplo Brevo:
#   ./scripts/setup_email.sh "p_..." "Minha Empresa" "meu@empresa.com" \
#       "smtp-relay.brevo.com" 587 "meu@empresa.com" "minha_api_key" "starttls"
# =============================================================================

PROJECT_ID="${1}"
SENDER_NAME="${2}"
FROM_EMAIL="${3}"
SMTP_HOST="${4}"
SMTP_PORT="${5:-587}"
SMTP_USER="${6}"
SMTP_PASS="${7}"
TLS_MODE="${8:-starttls}"

if [ -z "$PROJECT_ID" ] || [ -z "$FROM_EMAIL" ] || [ -z "$SMTP_HOST" ] || [ -z "$SMTP_PASS" ]; then
  echo "Uso: $0 <project_id> <nome> <email> <smtp_host> <porta> <usuario> <senha> <tls_mode>"
  echo ""
  echo "Exemplos de tls_mode: tls (porta 465), starttls (porta 587), none (porta 25)"
  exit 1
fi

SENDER_NAME="${SENDER_NAME:-Fluxo Email MKT}"

bin/keila rpc "
project_id = \"$PROJECT_ID\"
params = %{
  \"name\" => \"$SENDER_NAME\",
  \"from_name\" => \"$SENDER_NAME\",
  \"from_email\" => \"$FROM_EMAIL\",
  \"config\" => %{
    \"type\" => \"smtp\",
    \"smtp_relay\" => \"$SMTP_HOST\",
    \"smtp_port\" => $SMTP_PORT,
    \"smtp_username\" => \"$SMTP_USER\",
    \"smtp_password\" => \"$SMTP_PASS\",
    \"smtp_auth_method\" => \"password\",
    \"smtp_tls_mode\" => \"$TLS_MODE\"
  }
}

case Keila.Mailings.create_sender(project_id, params) do
  {:ok, sender} ->
    IO.puts(\"✅ Sender criado com sucesso: #{sender.id}\")
  {:action_required, sender} ->
    IO.puts(\"⚠️  Sender criado mas requer verificação: #{sender.id}\")
  {:error, changeset} ->
    IO.puts(\"❌ Erro: #{inspect(changeset.errors)}\")
end
"
