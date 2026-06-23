defmodule Keila.Consent.Log do
  @moduledoc """
  Registro imutável de prova de consentimento (LGPD).

  Ver `Keila.Consent` para a API.
  """
  use Keila.Schema, prefix: "cl"

  alias Keila.Projects.Project
  alias Keila.Contacts.Contact

  @legal_bases ~w(consent legitimate_interest contract)

  schema "consent_logs" do
    field :email, :string
    field :legal_basis, :string
    field :source, :string
    field :policy_version, :string
    field :policy_url, :string
    field :consent_text, :string
    field :double_opt_in, :boolean, default: false
    field :ip, :string
    field :user_agent, :string
    field :occurred_at, :utc_datetime

    belongs_to :project, Project, type: Project.Id
    belongs_to :contact, Contact, type: Contact.Id

    timestamps(updated_at: false)
  end

  @fields [
    :project_id,
    :contact_id,
    :email,
    :legal_basis,
    :source,
    :policy_version,
    :policy_url,
    :consent_text,
    :double_opt_in,
    :ip,
    :user_agent,
    :occurred_at
  ]

  @doc false
  def changeset(params) do
    %__MODULE__{}
    |> cast(params, @fields)
    |> validate_inclusion(:legal_basis, @legal_bases)
    |> validate_length(:user_agent, max: 500)
  end

  def legal_bases, do: @legal_bases
end
