defmodule Keila.Automations.Automation do
  @moduledoc """
  Uma automação ("Receita") ativa num projeto.

  Cada automação é instanciada a partir de uma `Recipe` (definida em código —
  ex: "lead_novo_boas_vindas") com seus passos pré-configurados, mas pode ser
  ativada/desativada por unidade.
  """
  use Keila.Schema, prefix: "auto"

  alias Keila.Projects.Project
  alias Keila.Integrations.Evo.Unit
  alias Keila.Automations.Step

  schema "automations" do
    field :name, :string
    field :recipe_slug, :string
    field :trigger_status, :string
    field :active, :boolean, default: true
    field :last_run_at, :utc_datetime
    field :total_runs, :integer, default: 0

    belongs_to :project, Project, type: Project.Id
    belongs_to :evo_unit, Unit, type: Unit.Id

    has_many :steps, Step, foreign_key: :automation_id, preload_order: [asc: :order]

    timestamps()
  end

  @creation_fields [
    :project_id,
    :evo_unit_id,
    :name,
    :recipe_slug,
    :trigger_status,
    :active
  ]

  @update_fields [:name, :evo_unit_id, :trigger_status, :active]

  def creation_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:project_id, :name, :recipe_slug])
  end

  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
    |> validate_required([:name])
  end
end
