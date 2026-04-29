defmodule KeilaWeb.BirthdaysController do
  @moduledoc """
  Tela "Aniversariantes" — mostra próximos aniversários da base e o status
  da automação de aniversário.

  IMPORTANTE: Aniversário SÓ vem de Members (alunos matriculados) da EVO.
  Prospects/Oportunidades NÃO têm campo birth_date na API da EVO.
  """
  use KeilaWeb, :controller

  alias Keila.Automations.Workers.BirthdayWorker
  alias Keila.Automations
  alias Keila.Automations.Workers.SyncWorker
  import Ecto.Query
  alias Keila.Repo
  alias Keila.Contacts.Contact

  def index(conn, _params) do
    project = current_project(conn)
    upcoming = BirthdayWorker.list_upcoming_birthdays(project.id, 30)

    total_members =
      from(c in Contact,
        where: c.project_id == ^project.id,
        where: fragment("?->>'evo_type' = 'member'", c.data),
        select: count(c.id)
      )
      |> Repo.one() || 0

    members_with_birthday =
      from(c in Contact,
        where: c.project_id == ^project.id,
        where: fragment("?->>'evo_type' = 'member'", c.data),
        where: fragment("?->>'birth_date' IS NOT NULL AND ?->>'birth_date' != ''", c.data, c.data),
        select: count(c.id)
      )
      |> Repo.one() || 0

    total_prospects =
      from(c in Contact,
        where: c.project_id == ^project.id,
        where: fragment("?->>'evo_id' IS NOT NULL", c.data),
        where:
          fragment(
            "(?->>'evo_type' IS NULL OR ?->>'evo_type' != 'member')",
            c.data,
            c.data
          ),
        select: count(c.id)
      )
      |> Repo.one() || 0

    total_contacts =
      from(c in Contact, where: c.project_id == ^project.id, select: count(c.id))
      |> Repo.one() || 0

    total_with_birthday =
      from(c in Contact,
        where: c.project_id == ^project.id,
        where: fragment("?->>'birth_date' IS NOT NULL AND ?->>'birth_date' != ''", c.data, c.data),
        select: count(c.id)
      )
      |> Repo.one() || 0

    automation_active =
      Automations.list_automations(project.id)
      |> Enum.any?(&(&1.recipe_slug == "aniversariantes" and &1.active))

    today_birthdays = BirthdayWorker.find_birthday_contacts(project.id)

    conn
    |> assign(:upcoming, upcoming)
    |> assign(:today_birthdays, today_birthdays)
    |> assign(:total_with_birthday, total_with_birthday)
    |> assign(:total_contacts, total_contacts)
    |> assign(:total_members, total_members)
    |> assign(:members_with_birthday, members_with_birthday)
    |> assign(:total_prospects, total_prospects)
    |> assign(:automation_active, automation_active)
    |> render("index.html")
  end

  @doc """
  Dispara sync EVO agora pro projeto e redireciona de volta.
  """
  def sync_now(conn, _params) do
    project = current_project(conn)

    Task.start(fn -> SyncWorker.sync_project(project.id) end)

    conn
    |> put_flash(
      :info,
      "🔄 Sincronizando members + oportunidades da EVO... volte aqui em 30 segundos. Aniversário só vem dos MEMBERS (alunos matriculados)."
    )
    |> redirect(to: "/projects/#{project.id}/aniversariantes")
  end

  defp current_project(conn), do: conn.assigns.current_project
end
