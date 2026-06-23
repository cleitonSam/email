defmodule Keila.Suppressions.Suppression do
  @moduledoc """
  Registro de supressão de um e-mail (trava dura de envio).

  Ver `Keila.Suppressions` para a API. `project_id` nulo = bloqueio global.
  """
  use Keila.Schema, prefix: "sup"

  alias Keila.Projects.Project

  @reasons ~w(hard_bounce complaint unsubscribe manual global_block import_invalid)

  schema "suppressions" do
    field :email, :string
    field :reason, :string
    field :source, :string
    field :notes, :string

    belongs_to :project, Project, type: Project.Id

    timestamps(updated_at: false)
  end

  @fields [:email, :project_id, :reason, :source, :notes]

  @doc false
  def changeset(params) do
    %__MODULE__{}
    |> cast(params, @fields)
    |> validate_required([:email, :reason])
    |> update_change(:email, &normalize_email/1)
    |> validate_inclusion(:reason, @reasons)
    |> unique_constraint([:project_id, :email],
      name: :suppressions_project_email_index
    )
    |> unique_constraint([:email], name: :suppressions_global_email_index)
  end

  @doc "Normaliza um e-mail para comparação/armazenamento (trim + lowercase)."
  def normalize_email(nil), do: nil
  def normalize_email(email) when is_binary(email), do: email |> String.trim() |> String.downcase()

  @doc "Lista de motivos válidos."
  def reasons, do: @reasons
end
