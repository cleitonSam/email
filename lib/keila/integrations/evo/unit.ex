defmodule Keila.Integrations.Evo.Unit do
  @moduledoc """
  Schema de uma unidade EVO conectada a um projeto.

  Cada unidade representa uma academia (ex: "Unidade Centro", "Unidade Zona Sul")
  com suas próprias credenciais EVO. Um projeto Fluxo pode ter N unidades — útil
  para redes/franquias gerenciadas por um operador único.
  """
  use Keila.Schema, prefix: "eu"

  alias Keila.Projects.Project

  schema "evo_units" do
    field :name, :string
    field :evo_dns, :string
    field :evo_secret_key, :string
    field :branch_label, :string
    field :cnpj, :string
    field :address, :string
    field :phone, :string
    field :is_primary, :boolean, default: false
    field :active, :boolean, default: true
    field :last_sync_at, :utc_datetime
    field :last_sync_status, :string
    field :last_sync_error, :string

    belongs_to :project, Project, type: Project.Id

    timestamps()
  end

  @creation_fields [
    :project_id,
    :name,
    :evo_dns,
    :evo_secret_key,
    :branch_label,
    :cnpj,
    :address,
    :phone,
    :is_primary,
    :active
  ]

  @update_fields [
    :name,
    :evo_dns,
    :evo_secret_key,
    :branch_label,
    :cnpj,
    :address,
    :phone,
    :is_primary,
    :active,
    :last_sync_at,
    :last_sync_status,
    :last_sync_error
  ]

  @spec creation_changeset(map()) :: Ecto.Changeset.t(t())
  def creation_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:project_id, :name, :evo_dns, :evo_secret_key])
    |> validate_length(:name, min: 1, max: 80)
    |> validate_length(:evo_dns, min: 1, max: 200)
    |> unique_constraint([:project_id, :evo_dns],
      message: "Esta unidade EVO já está cadastrada neste projeto."
    )
  end

  @spec update_changeset(t(), map()) :: Ecto.Changeset.t(t())
  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
    |> validate_required([:name, :evo_dns, :evo_secret_key])
    |> validate_length(:name, min: 1, max: 80)
    |> unique_constraint([:project_id, :evo_dns],
      message: "Esta unidade EVO já está cadastrada neste projeto."
    )
  end
end
