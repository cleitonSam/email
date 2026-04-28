defmodule Keila.Repo.Migrations.CreateEvoUnits do
  use Ecto.Migration

  def change do
    create table("evo_units") do
      add :project_id, references("projects", on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :evo_dns, :string, null: false
      add :evo_secret_key, :text, null: false
      add :branch_label, :string
      add :active, :boolean, default: true, null: false
      add :last_sync_at, :utc_datetime
      add :last_sync_status, :string
      add :last_sync_error, :text

      timestamps()
    end

    create index("evo_units", [:project_id])
    create unique_index("evo_units", [:project_id, :evo_dns])
  end
end
