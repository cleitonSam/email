defmodule Keila.Repo.Migrations.AddSystemCategoryAndUnitToCampaigns do
  use Ecto.Migration

  def change do
    alter table("contacts_segments") do
      add :system_category, :string
    end

    create unique_index("contacts_segments", [:project_id, :system_category],
             where: "system_category IS NOT NULL",
             name: :contacts_segments_project_system_category_index
           )

    alter table("mailings_campaigns") do
      add :unit_id, references("evo_units", on_delete: :nilify_all)
    end

    create index("mailings_campaigns", [:unit_id])
  end
end
