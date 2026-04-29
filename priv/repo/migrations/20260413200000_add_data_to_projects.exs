defmodule Keila.Repo.Migrations.AddDataToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :data, :map, default: %{}
    end
  end
end
