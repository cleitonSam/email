defmodule KeilaWeb.BirthdaysController do
  @moduledoc """
  Tela "Aniversariantes" — mostra próximos aniversários da base e o status
  da automação de aniversário.
  """
  use KeilaWeb, :controller

  alias Keila.Automations.Workers.BirthdayWorker
  alias Keila.Automations
  import Ecto.Query
  alias Keila.Repo
  alias Keila.Contacts.Contact

  def index(conn, _params) do
    project = current_project(conn)
    upcoming = BirthdayWorker.list_upcoming_birthdays(project.id, 30)

    # Total de contatos com birth_date preenchido
    total_with_birthday =
      from(c in Contact,
        where: c.project_id == ^project.id,
        where: fragment("? \\? 'birth_date'", c.data),
        where: fragment("?->>'birth_date' IS NOT NULL AND ?->>'birth_date' != ''", c.data, c.data),
        select: count(c.id)
      )
      |> Repo.one() || 0

    # Total geral de contatos
    total_contacts =
      from(c in Contact, where: c.project_id == ^project.id, select: count(c.id))
      |> Repo.one() || 0

    # Automação ativa?
    automation_active =
      Automations.list_automations(project.id)
      |> Enum.any?(&(&1.recipe_slug == "aniversariantes" and &1.active))

    today_birthdays = BirthdayWorker.find_birthday_contacts(project.id)

    conn
    |> assign(:upcoming, upcoming)
    |> assign(:today_birthdays, today_birthdays)
    |> assign(:total_with_birthday, total_with_birthday)
    |> assign(:total_contacts, total_contacts)
    |> assign(:automation_active, automation_active)
    |> render("index.html")
  end

  defp current_project(conn), do: conn.assigns.current_project
end
