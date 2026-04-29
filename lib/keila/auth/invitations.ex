defmodule Keila.Auth.Invitations do
  @moduledoc """
  Context pra gerenciar convites de usuário a projetos.
  """

  import Ecto.Query
  require Logger
  alias Keila.Repo
  alias Keila.Auth.Invitation
  alias Keila.Auth.User

  @spec list_pending(binary()) :: [Invitation.t()]
  def list_pending(project_id) do
    now = DateTime.utc_now()

    Invitation
    |> where([i], i.project_id == ^project_id)
    |> where([i], is_nil(i.accepted_at))
    |> where([i], i.expires_at > ^now)
    |> order_by([i], desc: i.inserted_at)
    |> preload(:invited_by_user)
    |> Repo.all()
  end

  @doc "Lista convites já aceitos (= membros ativos do projeto)."
  @spec list_accepted(binary()) :: [Invitation.t()]
  def list_accepted(project_id) do
    Invitation
    |> where([i], i.project_id == ^project_id)
    |> where([i], not is_nil(i.accepted_at))
    |> order_by([i], desc: i.accepted_at)
    |> preload([:invited_by_user, :accepted_by_user])
    |> Repo.all()
  end

  @spec get_by_token(String.t()) :: Invitation.t() | nil
  def get_by_token(token) when is_binary(token) and token != "" do
    Repo.get_by(Invitation, token: token)
    |> Repo.preload([:project, :invited_by_user])
  end

  def get_by_token(_), do: nil

  @spec valid?(Invitation.t() | nil) :: boolean()
  def valid?(nil), do: false
  def valid?(%Invitation{accepted_at: %DateTime{}}), do: false

  def valid?(%Invitation{expires_at: expires}) do
    DateTime.compare(DateTime.utc_now(), expires) == :lt
  end

  @spec create(map()) :: {:ok, Invitation.t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    with {:ok, invitation} <- params |> Invitation.creation_changeset() |> Repo.insert() do
      case send_invitation_email(invitation) do
        :ok -> {:ok, invitation}
        :error -> {:ok, invitation, :email_failed}
      end
    end
  end

  @spec accept(Invitation.t(), User.t()) :: {:ok, Invitation.t()} | {:error, term()}
  def accept(%Invitation{} = invitation, %User{} = user) do
    invitation
    |> Invitation.accept_changeset(user.id)
    |> Repo.update()
  end

  @spec revoke(Invitation.t()) :: {:ok, Invitation.t()} | {:error, term()}
  def revoke(%Invitation{} = invitation), do: Repo.delete(invitation)

  @spec get(binary()) :: Invitation.t() | nil
  def get(id), do: Repo.get(Invitation, id) |> Repo.preload([:project, :invited_by_user])

  defp send_invitation_email(%Invitation{} = invitation) do
    invitation = Repo.preload(invitation, [:project, :invited_by_user])
    accept_url = "#{base_url()}/invite/#{invitation.token}"

    inviter_name =
      case invitation.invited_by_user do
        %{email: email} when is_binary(email) -> email
        _ -> "Alguém"
      end

    project_name = (invitation.project && invitation.project.name) || "Fluxo Email MKT"

    params = %{
      url: accept_url,
      email: invitation.email,
      inviter: inviter_name,
      project_name: project_name
    }

    try do
      Keila.Auth.Emails.send!(:invitation, params)
      Logger.info("[Invitation] Sent to #{invitation.email}")
      :ok
    rescue
      e ->
        Logger.error("[Invitation] Failed to send to #{invitation.email}: #{inspect(e)}")
        :error
    end
  end

  defp base_url do
    scheme = System.get_env("URL_SCHEMA") || "https"
    host = System.get_env("URL_HOST") || "emailmkt.fluxodigitaltech.com.br"
    "#{scheme}://#{host}"
  end
end
