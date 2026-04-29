defmodule Keila.Repo.Migrations.CreateAutomations do
  use Ecto.Migration

  def change do
    create table("automations") do
      add :project_id, references("projects", on_delete: :delete_all), null: false
      add :evo_unit_id, references("evo_units", on_delete: :nilify_all)

      add :name, :string, null: false
      add :recipe_slug, :string, null: false
      add :trigger_status, :string
      add :active, :boolean, default: true, null: false

      add :last_run_at, :utc_datetime
      add :total_runs, :integer, default: 0

      timestamps()
    end

    create index("automations", [:project_id])
    create index("automations", [:project_id, :active])

    create table("automation_steps") do
      add :automation_id, references("automations", on_delete: :delete_all), null: false
      add :order, :integer, null: false
      add :delay_days, :integer, null: false, default: 0
      add :template_slug, :string, null: false
      add :subject, :string

      timestamps()
    end

    create index("automation_steps", [:automation_id])

    create table("automation_runs") do
      add :automation_id, references("automations", on_delete: :delete_all), null: false
      add :step_id, references("automation_steps", on_delete: :delete_all), null: false
      add :contact_id, references("contacts", on_delete: :delete_all), null: false

      add :scheduled_at, :utc_datetime, null: false
      add :executed_at, :utc_datetime
      add :status, :string, null: false, default: "pending"
      add :error, :text

      timestamps()
    end

    create index("automation_runs", [:status, :scheduled_at])
    create index("automation_runs", [:automation_id])
    create unique_index("automation_runs", [:automation_id, :step_id, :contact_id])
  end
end
