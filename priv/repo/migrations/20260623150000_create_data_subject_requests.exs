defmodule Keila.Repo.Migrations.CreateDataSubjectRequests do
  use Ecto.Migration

  @moduledoc """
  Pedidos de direitos do titular — Art. 18 LGPD (§ 4 do Prompt Mestre):
  acesso, correção, portabilidade, eliminação/anonimização, revogação, oposição.
  """

  def change do
    create table("data_subject_requests") do
      add :project_id, references("projects", on_delete: :delete_all)
      add :contact_id, references("contacts", on_delete: :nilify_all)
      add :email, :citext, null: false

      # access | rectification | portability | deletion | anonymization |
      # revoke_consent | object
      add :request_type, :string, null: false
      # pending | processing | completed | rejected
      add :status, :string, default: "pending", null: false

      add :details, :text
      add :handled_by_user_id, references("users", on_delete: :nilify_all)
      add :requested_at, :utc_datetime
      add :completed_at, :utc_datetime

      timestamps()
    end

    create index("data_subject_requests", [:project_id])
    create index("data_subject_requests", [:email])
    create index("data_subject_requests", [:status])
  end
end
