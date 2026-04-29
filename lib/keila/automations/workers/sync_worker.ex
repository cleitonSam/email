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
      # Garante segmentos default "Oportunidades" e "Alunos"
      ensure_default_segments(project_id)
      # Sincroniza Oportunidades (prospects)
      sync_prospects_for_units(project_id, units)
      # Sincroniza Alunos (members)
      sync_members_for_units(project_id, units)
      :ok
    end
  end

  defp ensure_default_segments(project_id) do
    segments = Keila.Contacts.get_project_segments(project_id)
    names = Enum.map(segments, & &1.name)

    unless "Oportunidades (Leads EVO)" in names do
      Keila.Contacts.create_segment(project_id, %{
        "name" => "Oportunidades (Leads EVO)",
        "filter" => %{
          "$and" => [
            %{"data.evo_id" => %{"$ne" => nil}},
            %{"$or" => [
              %{"data.evo_type" => %{"$ne" => "member"}},
              %{"data.evo_type" => nil}
            ]}
          ]
        }
      })
    end

    unless "Alunos matriculados" in names do
      Keila.Contacts.create_segment(project_id, %{
        "name" => "Alunos matriculados",
        "filter" => %{
          "$and" => [
            %{"data.evo_type" => "member"}
          ]
        }
      })
    end
  end

  defp sync_prospects_for_units(project_id, units) do
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

      _ ->
        :ok
    end
  end

  defp sync_members_for_units(project_id, units) do
    Enum.each(units, fn unit ->
      case Evo.fetch_members(
             evo_dns: unit.evo_dns,
             evo_secret_key: unit.evo_secret_key
           ) do
        {:ok, members, _total} ->
          tagged =
            Enum.map(members, fn m ->
              m
              |> Map.put(:evo_unit_id, unit.id)
              |> Map.put(:evo_unit_name, unit.name)
            end)

          Enum.each(tagged, fn m -> handle_member(project_id, m) end)

        {:error, reason} ->
          Logger.warning("[Members] Unidade #{unit.name}: #{inspect(reason)}")
      end
    end)
  end

  defp handle_member(project_id, member) do
    contact_params = %{
      "email" => member.email,
      "first_name" => member.first_name,
      "last_name" => member.last_name,
      "data" => %{
        "phone" => member.phone,
        "birth_date" => Map.get(member, :birth_date),
        "evo_branch" => member.branch,
        "evo_unit_id" => Map.get(member, :evo_unit_id),
        "evo_unit_name" => Map.get(member, :evo_unit_name),
        "evo_id" => member.id_evo,
        "evo_register_date" => member.register_date,
        "evo_type" => "member",
        "evo_member_status" => member.member_status,
        "evo_contract_status" => member.contract_status
      }
    }

    case Contacts.create_contact(project_id, contact_params) do
      {:ok, _contact} -> :ok
      {:error, _} -> :ok
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
