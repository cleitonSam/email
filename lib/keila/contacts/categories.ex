defmodule Keila.Contacts.Categories do
  @moduledoc """
  Catálogo de categorias de contato (segmentos do sistema).

  Cada categoria é materializada como um `Keila.Contacts.Segment` com a coluna
  `system_category` preenchida com o slug. Isso permite que o usuário escolha
  uma categoria como segmento ao disparar/agendar um email, e que o sistema
  reconheça/renove esses segmentos quando a definição mudar.

  Para adicionar uma nova categoria sem refactor:

      def catalog do
        [
          ...
          %{
            slug: "minha_categoria",
            name: "Minha Categoria",
            filter: %{...}
          }
        ]
      end

  O filtro segue a mesma sintaxe MongoDB-like usada em
  `Keila.Contacts.Query`.
  """

  alias Keila.Contacts
  alias Keila.Contacts.Segment
  alias Keila.Repo

  import Ecto.Query

  @type category :: %{
          slug: String.t(),
          name: String.t(),
          filter: map()
        }

  @spec catalog() :: [category()]
  def catalog do
    [
      %{
        slug: "aniversariantes",
        name: "Aniversariantes",
        filter: birthday_filter()
      },
      %{
        slug: "ausentes_1_7_dias",
        name: "Ausentes 1 a 7 dias",
        filter: absent_filter(1, 7)
      }
    ]
  end

  @spec get(String.t()) :: category() | nil
  def get(slug) do
    Enum.find(catalog(), &(&1.slug == slug))
  end

  @doc """
  Cria/atualiza os segmentos de sistema para um projeto.

  Idempotente: pode ser chamada múltiplas vezes sem duplicar.
  Atualiza nome e filtro caso a definição do catálogo tenha mudado.
  """
  @spec seed_for_project(any()) :: :ok
  def seed_for_project(project_id) do
    Enum.each(catalog(), fn category ->
      ensure_segment(project_id, category)
    end)

    :ok
  end

  @doc """
  Retorna o segmento de sistema (Segment) que materializa esta categoria
  no projeto, criando-o se necessário.
  """
  @spec get_or_create_segment(any(), String.t()) :: {:ok, Segment.t()} | {:error, term()}
  def get_or_create_segment(project_id, slug) do
    case get(slug) do
      nil ->
        {:error, :unknown_category}

      category ->
        {:ok, ensure_segment(project_id, category)}
    end
  end

  defp ensure_segment(project_id, category) do
    case Repo.one(
           from s in Segment,
             where: s.project_id == ^project_id and s.system_category == ^category.slug
         ) do
      nil ->
        {:ok, segment} =
          Contacts.create_segment(project_id, %{
            "name" => category.name,
            "filter" => category.filter,
            "system_category" => category.slug
          })

        segment

      segment ->
        {:ok, segment} =
          Contacts.update_segment(segment.id, %{
            "name" => category.name,
            "filter" => category.filter
          })

        segment
    end
  end

  # ----------------------------------------------------------------------------
  # Filter builders
  # ----------------------------------------------------------------------------

  # Aniversariantes do dia: filtra `data.birth_date` no formato MM-DD igualando
  # ao dia/mês de hoje. Os contatos importados do EVO armazenam `birth_date`
  # nesse formato (ano omitido).
  defp birthday_filter do
    today_mm_dd =
      Date.utc_today()
      |> then(fn d -> :io_lib.format("~2..0B-~2..0B", [d.month, d.day]) |> IO.iodata_to_binary() end)

    %{"data.birth_date" => today_mm_dd}
  end

  # Ausentes entre N e M dias: filtra `data.last_visit_at` (string ISO8601 ou
  # data) entre hoje-M e hoje-N. Quando a coluna estiver vazia, contato não
  # é incluído.
  defp absent_filter(min_days, max_days) do
    today = Date.utc_today()
    from_date = Date.add(today, -max_days) |> Date.to_iso8601()
    to_date = Date.add(today, -min_days) |> Date.to_iso8601()

    %{
      "$and" => [
        %{"data.last_visit_at" => %{"$gte" => from_date}},
        %{"data.last_visit_at" => %{"$lte" => to_date <> "T23:59:59Z"}}
      ]
    }
  end
end
