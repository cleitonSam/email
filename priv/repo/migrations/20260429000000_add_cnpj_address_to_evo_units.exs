defmodule Keila.Repo.Migrations.AddCnpjAddressToEvoUnits do
  use Ecto.Migration

  def change do
    alter table(:evo_units) do
      add :cnpj, :string, size: 20
      add :address, :string, size: 300
      add :phone, :string, size: 30
      add :is_primary, :boolean, default: false
    end

    create index(:evo_units, [:project_id, :is_primary])
  end
end
