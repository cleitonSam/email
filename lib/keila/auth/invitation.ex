defmodule Keila.Auth.Invitation do
  @moduledoc """
  Convite pra entrar num projeto.

  Admin/dono do projeto cria invitation com email do convidado.
  Sistema gera token único, manda email com link `/invite/:token`.
  Convidado clica → cria User + senha → é vinculado ao projeto.
  """
  use Keila.Schema, prefix: "inv"

  alias Keila.Projects.Project
  alias Keila.Auth.User

  schema "invitations" do
    field :email, :string
    field :token, :string
    field :role, :string, default: "member"
    field :expires_at, :utc_datetime
    field :accepted_at, :utc_datetime

    belongs_to :project, Project, type: Project.Id
    belongs_to :invited_by_user, User, type: User.Id, foreign_key: :invited_by_user_id
    belongs_to :accepted_by_user, User, type: User.Id, foreign_key: :accepted_by_user_id

    timestamps()
  end

  @creation_fields [:email, :project_id, :invited_by_user_id, :role]

  def creation_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:email, :project_id])
    |> validate_format(:email, ~r/@/, message: "Email inválido")
    |> put_token()
    |> put_expires_at()
  end

  def accept_changeset(struct, user_id) do
    struct
    |> cast(%{accepted_by_user_id: user_id}, [:accepted_by_user_id])
    |> put_change(:accepted_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  defp put_token(changeset) do
    case get_field(changeset, :token) do
      nil ->
        token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
        put_change(changeset, :token, token)

      _ ->
        changeset
    end
  end

  defp put_expires_at(changeset) do
    case get_field(changeset, :expires_at) do
      nil ->
        # 7 dias pra aceitar o convite
        expires =
          DateTime.utc_now()
          |> DateTime.add(7 * 86_400, :second)
          |> DateTime.truncate(:second)

        put_change(changeset, :expires_at, expires)

      _ ->
        changeset
    end
  end
end
