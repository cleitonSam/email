defmodule Keila.Automations do
  @moduledoc """
  Context principal pra automações ("Receitas Prontas").

  Funções:
  - list_automations/1 — todas automações de um projeto
  - activate_recipe/3 — ativa uma receita pra uma unidade (ou todas)
  - deactivate/1 — desativa
  - delete_automation/1
  - find_matching_automations/2 — pra um prospect, retorna automações que casam
  - schedule_runs/2 — pra um contato + automação, cria runs no calendário
  - process_pending_runs/0 — chamado pelo worker, dispara emails
  """

  import Ecto.Query
  alias Keila.Repo
  alias Keila.Automations.{Automation, Step, Run, Recipes}

  @spec list_automations(binary()) :: [Automation.t()]
  def list_automations(project_id) do
    Automation
    |> where([a], a.project_id == ^project_id)
    |> order_by([a], asc: a.inserted_at)
    |> preload([:steps, :evo_unit])
    |> Repo.all()
  end

  @spec get_automation(binary()) :: Automation.t() | nil
  def get_automation(id), do: Automation |> preload([:steps, :evo_unit]) |> Repo.get(id)

  @doc """
  Ativa uma receita pré-configurada pra um projeto, opcionalmente vinculada
  a uma unidade EVO (se evo_unit_id for nil = aplica a todas as unidades).

  Cria a Automation e os Steps em uma transação.
  """
  @spec activate_recipe(binary(), String.t(), binary() | nil) ::
          {:ok, Automation.t()} | {:error, term()}
  def activate_recipe(project_id, recipe_slug, evo_unit_id \\ nil) do
    with {:ok, recipe} <- Recipes.get(recipe_slug) do
      Repo.transaction(fn ->
        automation_params = %{
          project_id: project_id,
          evo_unit_id: evo_unit_id,
          name: recipe.title,
          recipe_slug: recipe_slug,
          trigger_status: recipe.trigger_status,
          active: true
        }

        case automation_params |> Automation.creation_changeset() |> Repo.insert() do
          {:ok, automation} ->
            Enum.each(recipe.steps, fn step ->
              params = %{
                automation_id: automation.id,
                order: step.order,
                delay_days: step.delay_days,
                template_slug: step.template_slug,
                subject: step[:subject]
              }

              case params |> Step.creation_changeset() |> Repo.insert() do
                {:ok, _} -> :ok
                {:error, cs} -> Repo.rollback(cs)
              end
            end)

            Repo.preload(automation, [:steps, :evo_unit])

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)
    end
  end

  @spec set_active(Automation.t(), boolean()) :: {:ok, Automation.t()} | {:error, term()}
  def set_active(%Automation{} = automation, active?) do
    automation
    |> Automation.update_changeset(%{active: active?})
    |> Repo.update()
  end

  @spec delete_automation(Automation.t()) :: {:ok, Automation.t()} | {:error, term()}
  def delete_automation(%Automation{} = a), do: Repo.delete(a)

  @doc """
  Para um prospect importado, retorna as automações ativas que casam com:
  - mesmo projeto
  - status do prospect bate com trigger_status (ou trigger_status é nil)
  - unidade do prospect bate com automation.evo_unit_id (ou é nil = global)
  """
  @spec find_matching_automations(binary(), map()) :: [Automation.t()]
  def find_matching_automations(project_id, prospect) do
    status = prospect[:status] || prospect["evo_status"]
    unit_id = prospect[:evo_unit_id] || prospect["evo_unit_id"]

    Automation
    |> where([a], a.project_id == ^project_id and a.active == true)
    |> where(
      [a],
      is_nil(a.trigger_status) or a.trigger_status == ^status
    )
    |> where(
      [a],
      is_nil(a.evo_unit_id) or a.evo_unit_id == ^unit_id
    )
    |> preload(:steps)
    |> Repo.all()
  end

  @doc """
  Agenda runs pra um contato em uma automação. Idempotente via unique constraint.
  """
  @spec schedule_runs(Automation.t(), binary()) :: :ok
  def schedule_runs(%Automation{} = automation, contact_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    automation = Repo.preload(automation, :steps)

    Enum.each(automation.steps, fn step ->
      scheduled_at = DateTime.add(now, step.delay_days * 86_400, :second)

      params = %{
        automation_id: automation.id,
        step_id: step.id,
        contact_id: contact_id,
        scheduled_at: scheduled_at,
        status: "pending"
      }

      params
      |> Run.creation_changeset()
      |> Repo.insert(on_conflict: :nothing)
    end)

    :ok
  end

  @doc """
  Lista runs pendentes que já passaram do scheduled_at.
  Chamado pelo worker Oban.
  """
  @spec list_due_runs(integer()) :: [Run.t()]
  def list_due_runs(limit \\ 100) do
    now = DateTime.utc_now()

    Run
    |> where([r], r.status == "pending" and r.scheduled_at <= ^now)
    |> order_by([r], asc: r.scheduled_at)
    |> limit(^limit)
    |> preload([:automation, :step, :contact])
    |> Repo.all()
  end

  @spec mark_run(Run.t(), :sent | :failed, String.t() | nil) :: {:ok, Run.t()}
  def mark_run(%Run{} = run, status, error \\ nil) do
    run
    |> Run.update_changeset(%{
      status: to_string(status),
      executed_at: DateTime.utc_now() |> DateTime.truncate(:second),
      error: error
    })
    |> Repo.update()
  end
end
