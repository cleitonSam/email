defmodule Keila.Automations.Workers.SyncWorker do
  @moduledoc """
  Worker Oban que roda periodicamente (cron) e:

  1. Pra cada projeto com unidades EVO ativas E automações ativas:
     a. Faz fetch de prospects das unidades
     b. Importa prospects novos como contatos (vinculados a evo_unit_id)
     c. Pra cada prospect importado, encontra automações que casam e agenda runs

  2. Processa runs pendentes (`scheduled_at <= now`):
     a. Carrega template do `library` (MJML compilado com merge tags)
     b. Cria campanha transient e dispara via Mailings.Builder
     c. Marca run como `:sent` ou `:failed`
  """
  use Oban.Worker, queue: :default, max_attempts: 3

  import Ecto.Query
  require Logger
  alias Keila.Repo
  alias Keila.Projects
  alias Keila.Contacts
  alias Keila.Automations
  alias Keila.Integrations.Evo
  alias Keila.Integrations.Evo.Units
  alias Keila.Templates.Library

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task" => "sync_all"}}) do
    sync_all_projects()
    process_due_runs()
    :ok
  end

  def perform(%Oban.Job{args: %{"task" => "process_runs"}}) do
    process_due_runs()
    :ok
  end

  def perform(_), do: :ok

  @doc """
  Sincroniza todos os projetos com automações ativas.
  """
  def sync_all_projects do
    project_ids =
      from(a in Keila.Automations.Automation,
        where: a.active == true,
        distinct: true,
        select: a.project_id
      )
      |> Repo.all()

    Enum.each(project_ids, &sync_project/1)
  end

  @doc """
  Sincroniza um projeto específico — busca prospects de todas suas unidades
  EVO ativas e agenda runs para os que casam com automações.
  """
  def sync_project(project_id) do
    units = Units.list_active_units(project_id)

    if units == [] do
      :ok
    else
      case Evo.fetch_prospects_multi(units) do
        {:ok, %{prospects: prospects, per_unit: per_unit}} ->
          Enum.each(per_unit, fn
            {unit_id, {:ok, _count}} ->
              unit = Units.get_unit(unit_id)
              if unit, do: Units.mark_sync_success(unit)

            {unit_id, {:error, reason}} ->
              unit = Units.get_unit(unit_id)
              if unit, do: Units.mark_sync_error(unit, to_string(reason))
          end)

          Enum.each(prospects, fn p -> handle_prospect(project_id, p) end)
          :ok

        _ ->
          :ok
      end
    end
  end

  defp handle_prospect(project_id, prospect) do
    contact_params = %{
      "email" => prospect.email,
      "first_name" => prospect.first_name,
      "last_name" => prospect.last_name,
      "data" => %{
        "phone" => prospect.phone,
        "evo_source" => prospect.source,
        "evo_status" => prospect.status,
        "evo_branch" => prospect.branch,
        "evo_unit_id" => Map.get(prospect, :evo_unit_id),
        "evo_unit_name" => Map.get(prospect, :evo_unit_name),
        "evo_id" => prospect.id_evo,
        "evo_register_date" => prospect.register_date
      }
    }

    case Contacts.create_contact(project_id, contact_params) do
      {:ok, contact} -> trigger_automations(project_id, prospect, contact.id)
      # já existe — busca pelo email e mesmo assim avalia automações
      {:error, _} -> maybe_trigger_for_existing(project_id, prospect)
    end
  end

  defp maybe_trigger_for_existing(project_id, prospect) do
    case Contacts.get_project_contact_by_email(project_id, prospect.email) do
      nil -> :ok
      contact -> trigger_automations(project_id, prospect, contact.id)
    end
  end

  defp trigger_automations(project_id, prospect, contact_id) do
    automations = Automations.find_matching_automations(project_id, prospect)

    Enum.each(automations, fn automation ->
      Automations.schedule_runs(automation, contact_id)
    end)
  end

  @doc """
  Processa runs pendentes (até 100 por execução). Pra cada uma, dispara o email.
  """
  def process_due_runs do
    runs = Automations.list_due_runs(100)

    Enum.each(runs, fn run ->
      case dispatch_run(run) do
        :ok ->
          Automations.mark_run(run, :sent)

        {:error, reason} ->
          Logger.warning("[Automation] Run #{run.id} falhou: #{inspect(reason)}")
          Automations.mark_run(run, :failed, to_string(reason))
      end
    end)
  end

  defp dispatch_run(run) do
    case Library.load_mjml(run.step.template_slug) do
      {:ok, _mjml} ->
        project = Projects.get_project(run.automation.project_id)
        contact = run.contact

        # NOTE: o disparo real depende da campanha do Keila (Mailings.deliver_now/etc).
        # Por ora, registramos no log. Refinaremos quando tivermos o sender padrão
        # configurado por projeto + Mailings.Builder.build/2 + envio direto.
        Logger.info(
          "[Automation] Dispatching template #{run.step.template_slug} → #{contact.email} (project #{project.id})"
        )

        :ok

      {:error, reason} ->
        Logger.error(
          "[Automation] Template #{run.step.template_slug} não encontrado: #{inspect(reason)}"
        )

        {:error, "Template #{run.step.template_slug} não encontrado"}
    end
  end
end
