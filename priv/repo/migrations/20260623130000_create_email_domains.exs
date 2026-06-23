defmodule Keila.Repo.Migrations.CreateEmailDomains do
  use Ecto.Migration

  @moduledoc """
  Domínios de envio por empresa/projeto + estado da verificação de DNS
  (regra inegociável nº 1 do Prompt Mestre: sem domínio validado, sem disparo).

  Guarda o resultado da última checagem de SPF/DKIM/DMARC. O gate de envio
  consulta `status`: enquanto não houver um registro `verified` para o domínio
  do remetente, o comportamento é progressivo (ver `Keila.Deliverability`).
  """

  def change do
    create table("email_domains") do
      add :project_id, references("projects", on_delete: :delete_all), null: false
      add :domain, :citext, null: false
      add :status, :string, default: "pending", null: false

      add :spf_ok, :boolean
      add :dmarc_ok, :boolean
      add :dkim_ok, :boolean
      add :dkim_selector, :string

      add :last_checked_at, :utc_datetime
      add :last_error, :text

      timestamps()
    end

    create unique_index("email_domains", [:project_id, :domain])
    create index("email_domains", [:status])
  end
end
