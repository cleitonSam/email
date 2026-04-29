defmodule Keila.Templates.Library do
  @moduledoc """
  Biblioteca de modelos prontos de email focados em academia.

  Os MJML originais ficam em `priv/email_templates/library/`. Cada modelo tem
  metadata (slug, título, descrição, tag, hero image) e o conteúdo MJML que
  vira o `mjml_body` de uma nova campanha quando o usuário clicar em
  "Usar este modelo".
  """

  @library_dir "priv/email_templates/library"

  @models [
    %{
      slug: "01-boas-vindas-matricula",
      title: "Boas-vindas matrícula",
      tag: "Lead novo",
      description:
        "Para novos alunos que acabaram de fechar plano. Acolhe e convida pra avaliação física.",
      preview_url: "/email-previews/01-boas-vindas-matricula"
    },
    %{
      slug: "02-feliz-aniversario",
      title: "Feliz aniversário",
      tag: "Retenção",
      description:
        "Mensagem afetiva no aniversário. Reforça vínculo e oferece presente da academia.",
      preview_url: "/email-previews/02-feliz-aniversario"
    },
    %{
      slug: "03-oferta-limitada",
      title: "Oferta limitada",
      tag: "Conversão",
      description:
        "Promoção com prazo. Senso de urgência sem ser apelativo. Bom pra leads frios.",
      preview_url: "/email-previews/03-oferta-limitada"
    },
    %{
      slug: "04-newsletter-mes",
      title: "Newsletter do mês",
      tag: "Comunidade",
      description: "Resumo mensal: aulas novas, eventos, dicas. Mantém base aquecida.",
      preview_url: "/email-previews/04-newsletter-mes"
    },
    %{
      slug: "05-avaliacao-fisica",
      title: "Avaliação física",
      tag: "Engajamento",
      description: "Convida o aluno pra fazer (ou refazer) avaliação. Reativa quem sumiu.",
      preview_url: "/email-previews/05-avaliacao-fisica"
    },
    %{
      slug: "06-convite-evento",
      title: "Convite evento",
      tag: "Engajamento",
      description: "Aula aberta, workshop, desafio. Aumenta presença e fortalece comunidade.",
      preview_url: "/email-previews/06-convite-evento"
    },
    %{
      slug: "07-reativacao-aluno",
      title: "Reativação aluno",
      tag: "Win-back",
      description: "Pra alunos sumidos há semanas. Tom acolhedor, sem culpa, com porta aberta.",
      preview_url: "/email-previews/07-reativacao-aluno"
    },
    %{
      slug: "08-indicacao-amigo",
      title: "Indicação amigo",
      tag: "Crescimento",
      description: "Programa de indicação. Aluno indica amigo e ambos ganham.",
      preview_url: "/email-previews/08-indicacao-amigo"
    }
  ]

  @doc """
  Lista todos os modelos disponíveis (apenas metadata, sem o MJML carregado).
  """
  @spec list_models() :: [map()]
  def list_models, do: @models

  @doc """
  Busca um modelo pelo slug. Retorna `{:ok, metadata}` ou `{:error, :not_found}`.
  """
  @spec get_model(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_model(slug) do
    case Enum.find(@models, &(&1.slug == slug)) do
      nil -> {:error, :not_found}
      model -> {:ok, model}
    end
  end

  @doc """
  Carrega o conteúdo MJML completo de um modelo.

  Retorna `{:ok, mjml_string}` ou `{:error, reason}`.
  """
  @spec load_mjml(String.t()) :: {:ok, String.t()} | {:error, atom()}
  def load_mjml(slug) do
    with {:ok, _model} <- get_model(slug),
         path <- Path.join([Application.app_dir(:keila), @library_dir, "#{slug}.mjml"]),
         {:ok, content} <- File.read(path) do
      {:ok, content}
    else
      {:error, reason} when is_atom(reason) -> {:error, reason}
      _ -> {:error, :file_not_found}
    end
  end

  @doc """
  Default subject sugerido por modelo.
  """
  @spec default_subject(String.t()) :: String.t()
  def default_subject(slug) do
    case slug do
      "01-boas-vindas-matricula" -> "Bem-vindo(a) ao time, {{ first_name }}"
      "02-feliz-aniversario" -> "🎂 Hoje o dia é seu, {{ first_name }}!"
      "03-oferta-limitada" -> "{{ first_name }}, oferta termina em breve"
      "04-newsletter-mes" -> "O que rolou em {{ mes_referencia }}"
      "05-avaliacao-fisica" -> "{{ first_name }}, hora de medir o quanto você evoluiu"
      "06-convite-evento" -> "Você está convidado(a): {{ data_evento }}"
      "07-reativacao-aluno" -> "{{ first_name }}, a gente sente sua falta"
      "08-indicacao-amigo" -> "Treina com quem você ama 💪"
      _ -> ""
    end
  end

  @doc """
  Aplica os valores do brand do projeto direto no MJML, substituindo as
  variaveis Liquid `{{ brand.X }}` (com ou sem `default:`) pelos valores
  reais. Assim a campanha nasce ja com a paleta da empresa em vez dos
  fallbacks genericos.
  """
  @spec apply_brand(String.t(), map()) :: String.t()
  def apply_brand(mjml, brand) when is_binary(mjml) and is_map(brand) do
    keys = ["color_primary", "color_dark", "color_accent", "color_text", "logo_url", "name"]

    Enum.reduce(keys, mjml, fn key, acc ->
      value = Map.get(brand, key) || ""

      if value != "" do
        replace_brand_var(acc, key, value)
      else
        acc
      end
    end)
  end

  def apply_brand(mjml, _), do: mjml

  defp replace_brand_var(mjml, key, value) do
    # Pattern 1: {{ brand.KEY | default: 'whatever' }}
    pattern_with_default = ~r/\{\{\s*brand\.#{key}\s*\|\s*default:\s*\'[^\']*\'\s*\}\}/
    # Pattern 2: {{ brand.KEY }}
    pattern_simple = ~r/\{\{\s*brand\.#{key}\s*\}\}/

    mjml
    |> String.replace(pattern_with_default, value)
    |> String.replace(pattern_simple, value)
  end
end
