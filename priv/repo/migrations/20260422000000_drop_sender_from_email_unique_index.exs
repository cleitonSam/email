defmodule Keila.Repo.Migrations.DropSenderFromEmailUniqueIndex do
  use Ecto.Migration

  def change do
    drop_if_exists unique_index("mailings_senders", [:from_email])
  end
end
