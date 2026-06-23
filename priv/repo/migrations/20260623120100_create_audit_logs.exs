defmodule Keila.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  @moduledoc """
  Trilha de auditoria (regra inegociável nº 8 do Prompt Mestre).

  Registra TODA ação crítica: login, import/export de contatos, mudança de
  permissão, impersonation (modo suporte), cadastro/aprovação/bloqueio de
  empresa, disparo de campanha, etc.

  `actor_email` é uma cópia denormalizada para a trilha sobreviver mesmo que o
  usuário seja excluído depois. `metadata` guarda contexto livre (jsonb).
  """

  def change do
    create table("audit_logs") do
      add :action, :string, null: false
      add :actor_user_id, references("users", on_delete: :nilify_all)
      add :actor_email, :string
      add :entity_type, :string
      add :entity_id, :string
      add :project_id, references("projects", on_delete: :nilify_all)
      add :ip, :string
      add :user_agent, :string
      add :metadata, :map

      timestamps(updated_at: false)
    end

    create index("audit_logs", [:actor_user_id])
    create index("audit_logs", [:project_id])
    create index("audit_logs", [:action])
    create index("audit_logs", [:entity_type, :entity_id])
    create index("audit_logs", [:inserted_at])
  end
end
