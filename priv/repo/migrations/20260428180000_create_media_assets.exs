defmodule Keila.Repo.Migrations.CreateMediaAssets do
  use Ecto.Migration

  def change do
    create table("media_assets") do
      add :project_id, references("projects", on_delete: :delete_all), null: false

      add :imagekit_file_id, :string, null: false
      add :url, :string, null: false, size: 1000
      add :thumbnail_url, :string, size: 1000

      add :filename, :string, null: false
      add :mime_type, :string
      add :size_bytes, :integer
      add :width, :integer
      add :height, :integer

      add :folder, :string, default: "geral"
      add :tags, {:array, :string}, default: []
      add :alt_text, :string

      add :uploaded_by_user_id, :integer

      timestamps()
    end

    create index("media_assets", [:project_id])
    create index("media_assets", [:project_id, :folder])
    create unique_index("media_assets", [:imagekit_file_id])
  end
end
