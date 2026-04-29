defmodule Keila.Repo.Migrations.CreateInvitations do
  use Ecto.Migration

  def change do
    create table("invitations") do
      add :email, :citext, null: false
      add :token, :string, null: false
      add :project_id, references("projects", on_delete: :delete_all), null: false
      add :invited_by_user_id, references("users", on_delete: :nilify_all)
      add :role, :string, default: "member", null: false
      add :expires_at, :utc_datetime, null: false
      add :accepted_at, :utc_datetime
      add :accepted_by_user_id, references("users", on_delete: :nilify_all)

      timestamps()
    end

    create unique_index("invitations", [:token])
    create index("invitations", [:project_id])
    create index("invitations", [:email])
  end
end
