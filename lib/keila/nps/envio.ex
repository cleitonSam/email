defmodule Keila.Nps.Envio do
  @moduledoc """
  Envio de uma pesquisa de NPS a um contato.

  Cada envio tem um token único usado na URL pública de resposta
  (/nps/:token). Status: "pendente" | "enviado" | "respondido" | "bounce".
  """
  use Keila.Schema, prefix: "npse"

  alias Keila.Nps.{Pesquisa, Resposta}
  alias Keila.Contacts.Contact

  @statuses ~w(pendente enviado respondido bounce)

  schema "nps_envios" do
    field :token, :string
    field :status, :string, default: "pendente"
    field :enviado_em, :utc_datetime

    belongs_to :pesquisa, Pesquisa, type: Pesquisa.Id
    belongs_to :contato, Contact, type: Contact.Id
    has_one :resposta, Resposta

    timestamps()
  end

  @doc "Changeset para criar um envio (gera o token automaticamente)."
  def creation_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:pesquisa_id, :contato_id, :status, :enviado_em])
    |> validate_required([:pesquisa_id, :contato_id])
    |> validate_inclusion(:status, @statuses)
    |> put_token()
    |> unique_constraint(:token)
  end

  @doc "Changeset para mudar só o status do envio."
  def status_changeset(struct, status) do
    struct
    |> cast(%{status: status}, [:status])
    |> validate_inclusion(:status, @statuses)
  end

  defp put_token(changeset) do
    case get_field(changeset, :token) do
      nil ->
        token = :crypto.strong_rand_bytes(20) |> Base.url_encode64(padding: false)
        put_change(changeset, :token, token)

      _ ->
        changeset
    end
  end
end
