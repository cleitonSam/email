defmodule Keila.Repo.Migrations.AddLegalBasisAndConsentLogs do
  use Ecto.Migration

  @moduledoc """
  LGPD § 4 do Prompt Mestre: base legal e prova de consentimento por contato.

    - `contacts.legal_basis`: consent | legitimate_interest | contract
    - `contacts.source`: origem do contato (form | import | api | manual | integration)
    - `consent_logs`: registro imutável da prova de consentimento (texto exibido,
      versão da política, IP, user-agent, momento). Mantido mesmo após exclusão do
      contato (`contact_id` vira nulo) para preservar a prova.
  """

  def change do
    alter table("contacts") do
      add :legal_basis, :string
      add :source, :string
    end

    create index("contacts", [:legal_basis])

    create table("consent_logs") do
      add :project_id, references("projects", on_delete: :delete_all)
      add :contact_id, references("contacts", on_delete: :nilify_all)
      add :email, :citext

      add :legal_basis, :string
      add :source, :string
      add :policy_version, :string
      add :policy_url, :string
      add :consent_text, :text
      add :double_opt_in, :boolean, default: false, null: false

      add :ip, :string
      add :user_agent, :string
      add :occurred_at, :utc_datetime

      timestamps(updated_at: false)
    end

    create index("consent_logs", [:contact_id])
    create index("consent_logs", [:project_id])
    create index("consent_logs", [:email])
  end
end
