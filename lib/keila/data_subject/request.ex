defmodule Keila.DataSubject.Request do
  @moduledoc """
  Pedido de direito do titular (Art. 18 LGPD). Ver `Keila.DataSubject`.
  """
  use Keila.Schema, prefix: "dsr"

  alias Keila.Projects.Project
  alias Keila.Contacts.Contact
  alias Keila.Auth.User

  @types ~w(access rectification portability deletion anonymization revoke_consent object)
  @statuses ~w(pending processing completed rejected)

  schema "data_subject_requests" do
    field :email, :string
    field :request_type, :string
    field :status, :string, default: "pending"
    field :details, :string
    field :requested_at, :utc_datetime
    field :completed_at, :utc_datetime

    belongs_to :project, Project, type: Project.Id
    belongs_to :contact, Contact, type: Contact.Id
    belongs_to :handled_by, User, type: User.Id, foreign_key: :handled_by_user_id

    timestamps()
  end

  @doc "Changeset de criação (titular solicita)."
  def creation_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:project_id, :contact_id, :email, :request_type, :details])
    |> validate_required([:email, :request_type])
    |> update_change(:email, &normalize/1)
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+$/, message: "E-mail inválido")
    |> validate_inclusion(:request_type, @types)
    |> put_change(:requested_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc "Changeset para o atendente atualizar o status."
  def status_changeset(struct, params) do
    struct
    |> cast(params, [:status, :handled_by_user_id, :completed_at, :details])
    |> validate_inclusion(:status, @statuses)
  end

  defp normalize(nil), do: nil
  defp normalize(email), do: email |> String.trim() |> String.downcase()

  def types, do: @types
  def statuses, do: @statuses
end
