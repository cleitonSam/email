defmodule Keila.Repo.Migrations.CreateEmpresas do
  use Ecto.Migration

  def change do
    create table("empresas") do
      add :nome, :string, null: false
      add :cnpj, :string, size: 20, null: false
      add :status, :string, default: "convidada", null: false
      add :email_responsavel, :string
      add :project_id, references("projects", on_delete: :delete_all)

      timestamps()
    end

    create unique_index("empresas", [:cnpj])
    create index("empresas", [:project_id])
  end
end
