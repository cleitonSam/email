defmodule Keila.Automations.Workers.BirthdayWorker do
  @moduledoc """
  Worker que roda DIARIAMENTE às 9h e identifica contatos que fazem aniversário
  hoje (com base em `data.birth_date` em formato "MM-DD"). Pra cada projeto que
  tem automação "aniversariantes" ativa, agenda um run pra cada aniversariante.

  birth_date pode vir de 3 lugares:
  1. EVO members API (campo `birthDate`)
  2. Import de planilha CSV (coluna data_nascimento)
  3. Cadastro manual no contato

  Formato armazenado em `data.birth_date`: "MM-DD" (ex: "04-29" pra 29 de abril).
  Não armazena ano — só interessa o dia/mês pra disparar todo ano no aniversário.
  """
  use Oban.Worker, queue: :default, max_attempts: 1

  import Ecto.Query
  require Logger
  alias Keila.Repo
  alias Keila.Contacts.Contact
  alias Keila.Automations
  alias Keila.Automations.Automation

  @impl Oban.Worker
  def perform(_job) do
    today_md = today_md()

    # Encontra todas automações ativas com slug "aniversariantes"
    automations =
      from(a in Automation,
        where: a.active == true and a.recipe_slug == "aniversariantes"
      )
      |> Repo.all()
      |> Repo.preload(:steps)

    Enum.each(automations, fn automation ->
      birthday_contacts = find_birthday_contacts(automation.project_id, today_md)

      Logger.info(
        "[Birthday] Project #{automation.project_id}: #{length(birthday_contacts)} aniversariantes hoje (#{today_md})"
      )

      Enum.each(birthday_contacts, fn contact ->
        Automations.schedule_runs(automation, contact.id)
      end)
    end)

    :ok
  end

  @doc """
  Lista contatos de um projeto que fazem aniversário em uma data MM-DD.

  Se `date_md` é nil, usa hoje.
  """
  @spec find_birthday_contacts(binary(), String.t() | nil) :: [Contact.t()]
  def find_birthday_contacts(project_id, date_md \\ nil) do
    md = date_md || today_md()

    from(c in Contact,
      where: c.project_id == ^project_id,
      where: fragment("?->>'birth_date' = ?", c.data, ^md)
    )
    |> Repo.all()
  end

  @doc """
  Lista próximos aniversariantes de um projeto (próximos N dias).
  """
  @spec list_upcoming_birthdays(binary(), integer()) :: [{String.t(), [Contact.t()]}]
  def list_upcoming_birthdays(project_id, days \\ 30) do
    today = Date.utc_today()

    1..days
    |> Enum.map(fn offset ->
      day = Date.add(today, offset - 1)
      md = format_md(day)
      {md, Date.to_iso8601(day), find_birthday_contacts(project_id, md)}
    end)
    |> Enum.filter(fn {_, _, contacts} -> contacts != [] end)
    |> Enum.map(fn {md, iso, contacts} -> %{md: md, iso: iso, contacts: contacts} end)
  end

  defp today_md do
    today = Date.utc_today()
    format_md(today)
  end

  defp format_md(date) do
    month = date.month |> Integer.to_string() |> String.pad_leading(2, "0")
    day = date.day |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{month}-#{day}"
  end
end
