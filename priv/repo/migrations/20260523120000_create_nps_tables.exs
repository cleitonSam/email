defmodule Keila.Repo.Migrations.CreateNpsTables do
  use Ecto.Migration

  def change do
    create table("nps_pesquisas") do
      add :project_id, references("projects", on_delete: :delete_all), null: false
      add :nome, :string, null: false
      add :pergunta, :string, size: 500, null: false
      add :status, :string, default: "rascunho", null: false

      timestamps()
    end

    create index("nps_pesquisas", [:project_id])

    create table("nps_envios") do
      add :pesquisa_id, references("nps_pesquisas", on_delete: :delete_all), null: false
      add :contato_id, references("contacts", on_delete: :delete_all), null: false
      add :token, :string, null: false
      add :status, :string, default: "pendente", null: false
      add :enviado_em, :utc_datetime

      timestamps()
    end

    create unique_index("nps_envios", [:token])
    create index("nps_envios", [:pesquisa_id])
    create index("nps_envios", [:contato_id])

    create table("nps_respostas") do
      add :envio_id, references("nps_envios", on_delete: :delete_all), null: false
      add :nota, :integer, null: false
      add :categoria, :string, null: false
      add :comentario, :text
      add :respondido_em, :utc_datetime

      timestamps()
    end

    create unique_index("nps_respostas", [:envio_id])
  end
end
