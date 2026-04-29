defmodule Keila.Automations.Run do
  @moduledoc """
  Uma execução pendente/feita de um passo de automação pra um contato específico.

  Quando um lead casa com o trigger de uma automação, criamos N runs (um por step),
  cada um agendado pra `scheduled_at` (now + step.delay_days). Worker Oban processa
  os pendentes e atualiza pra `:sent` ou `:failed`.
  """
  use Keila.Schema, prefix: "run"

  alias Keila.Automations.{Automation, Step}
  alias Keila.Contacts.Contact

  schema "automation_runs" do
    field :scheduled_at, :utc_datetime
    field :executed_at, :utc_datetime
    field :status, :string, default: "pending"
    field :error, :string

    belongs_to :automation, Automation, type: Automation.Id
    belongs_to :step, Step, type: Step.Id
    belongs_to :contact, Contact, type: Contact.Id

    timestamps()
  end

  def creation_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:automation_id, :step_id, :contact_id, :scheduled_at, :status])
    |> validate_required([:automation_id, :step_id, :contact_id, :scheduled_at])
    |> unique_constraint([:automation_id, :step_id, :contact_id])
  end

  def update_changeset(struct, params) do
    struct
    |> cast(params, [:status, :executed_at, :error])
  end
end
