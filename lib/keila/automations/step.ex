defmodule Keila.Automations.Step do
  @moduledoc """
  Um passo de uma automação — define delay (em dias) e qual template enviar.
  """
  use Keila.Schema, prefix: "step"

  alias Keila.Automations.Automation

  schema "automation_steps" do
    field :order, :integer
    field :delay_days, :integer, default: 0
    field :template_slug, :string
    field :subject, :string

    belongs_to :automation, Automation, type: Automation.Id

    timestamps()
  end

  def creation_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:automation_id, :order, :delay_days, :template_slug, :subject])
    |> validate_required([:automation_id, :order, :delay_days, :template_slug])
  end
end
