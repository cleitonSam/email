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

    # Total de MEMBERS (alunos matriculados — esses sim têm birth_date)
    total_members =
      from(c in Contact,
        where: c.project_id == ^project.id,
        where: fragment("?->>'evo_type' = 'member'", c.data),
        select: count(c.id)
      )
      |> Repo.one() || 0

    # Members COM birth_date preenchida
    members_with_birthday =
      from(c in Contact,
        where: c.project_id == ^project.id,
        where: fragment("?->>'evo_type' = 'member'", c.data),
        where: fragment("?->>'birth_date' IS NOT NULL AND ?->>'birth_date' != ''", c.data, c.data),
        select: count(c.id)
      )
      |> Repo.one() || 0

    # Total de OPORTUNIDADES (prospects — não têm birth_date)
    total_prospects =
      from(c in Contact,
        where: c.project_id == ^project.id,
        where: fragment("?->>'evo_id' IS NOT NULL", c.data),
        where:
          fragment(
            "(?->>'evo_t