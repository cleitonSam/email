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
  Aplica os valores do brand do projeto direto no MJML/HTML, substituindo:

    * Variaveis Liquid `{{ brand.X }}` (com ou sem `default:`)
    * Cores hardcoded conhecidas dos templates (#FF5A1F, #F97316 -> primary;
      #0A0E27, #1E2749 -> dark; #C4FF00 -> accent)
    * URLs placeholder de logo (placehold.co/...ACADEMIA*) -> logo_url
    * Nome generico "Academia Movimento" -> brand.name

  Funciona tanto em MJML cru quanto em HTML compilado, ja que sao
  substituicoes de string puras.
  """
  @spec apply_brand(String.t(), map()) :: String.t()
  def apply_brand(content, brand) when is_binary(content) and is_map(brand) do
    keys = ["color_primary", "color_dark", "color_accent", "color_text", "logo_url", "name"]

    content
    |> apply_liquid_vars(brand, keys)
    |> apply_hex_substitutions(brand)
    |> apply_smart_contrast(brand)
    |> apply_placeholder_substitutions(brand)
  end

  def apply_brand(content, _), do: content

  # ── Liquid {{ brand.X }} ──
  defp apply_liquid_vars(content, brand, keys) do
    Enum.reduce(keys, content, fn key, acc ->
      value = Map.get(brand, key) || ""
      if value != "", do: replace_brand_var(acc, key, value), else: acc
    end)
  end

  defp replace_brand_var(content, key, value) do
    pattern_with_default = ~r/\{\{\s*brand\.#{key}\s*\|\s*default:\s*\'[^\']*\'\s*\}\}/
    pattern_simple = ~r/\{\{\s*brand\.#{key}\s*\}\}/

    content
    |> String.replace(pattern_with_default, value)
    |> String.replace(pattern_simple, value)
  end

  # ── Cores hardcoded → slots da marca ──
  # Mapeamento de hex codes que aparecem hardcoded nos 8 templates
  # padroes do Fluxo. Quando o brand do projeto tem o slot definido,
  # substitui CASE-INSENSITIVE em todo o conteudo.
  @hex_map %{
    # Primary (laranja Fluxo): aparece como #FF5A1F nos defaults Liquid
    # e como #F97316 (orange-500 Tailwind) hardcoded em alguns templates
    "color_primary" => ["#FF5A1F", "#F97316", "#ff5a1f", "#f97316"],

    # Dark (navy): #0A0E27 e a variante mais clara #1E2749
    "color_dark" => ["#0A0E27", "#1E2749", "#0a0e27", "#1e2749"],

    # Accent (lime): #C4FF00
    "color_accent" => ["#C4FF00", "#c4ff00"]
  }

  defp apply_hex_substitutions(content, brand) do
    Enum.reduce(@hex_map, content, fn {brand_key, hex_list}, acc ->
      value = Map.get(brand, brand_key) || ""

      if value != "" and String.starts_with?(value, "#") do
        Enum.reduce(hex_list, acc, fn hex, inner_acc ->
          String.replace(inner_acc, hex, value)
        end)
      else
        acc
      end
    end)
  end

  # ── Placeholders de logo + nome generico ──
  @logo_placeholders [
    "https://placehold.co/240x80/0C4A6E/FFFFFF/png?text=ACADEMIA+MOVIMENTO",
    "https://placehold.co/140x44/0A0E27/FFFFFF/png?text=ACADEMIA"
  ]

  defp apply_placeholder_substitutions(content, brand) do
    logo = Map.get(brand, "logo_url") || ""
    name = Map.get(brand, "name") || ""

    content
    |> maybe_replace_logo(logo)
    |> maybe_replace_name(name)
  end

  defp maybe_replace_logo(content, ""), do: content

  defp maybe_replace_logo(content, logo_url) do
    Enum.reduce(@logo_placeholders, content, fn placeholder, acc ->
      String.replace(acc, placeholder, logo_url)
    end)
  end

  defp maybe_replace_name(content, ""), do: content

  defp maybe_replace_name(content, name) do
    String.replace(content, "Academia Movimento", name)
  end

  # ── Contraste inteligente (WCAG luminance) ──
  # Se a cor primaria/dark for clara, texto branco em cima fica invisivel.
  # Detecta via luminancia e troca pra texto escuro nas areas afetadas.

  @doc """
  Devolve o hex de texto legivel em cima de uma cor de fundo.
  Usa luminancia relativa (WCAG) com threshold 0.55.
  """
  @spec contrast_text(String.t()) :: String.t()
  def contrast_text(hex) when is_binary(hex) do
    case luminance(hex) do
      :error -> "#FFFFFF"
      l when l > 0.55 -> "#0A0E27"
      _ -> "#FFFFFF"
    end
  end

  def contrast_text(_), do: "#FFFFFF"

  defp luminance("#" <> hex), do: luminance(hex)

  defp luminance(hex) when byte_size(hex) == 6 do
    with {r, ""} <- Integer.parse(binary_part(hex, 0, 2), 16),
         {g, ""} <- Integer.parse(binary_part(hex, 2, 2), 16),
         {b, ""} <- Integer.parse(binary_part(hex, 4, 2), 16) do
      rl = channel_lum(r / 255)
      gl = channel_lum(g / 255)
      bl = channel_lum(b / 255)
      0.2126 * rl + 0.7152 * gl + 0.0722 * bl
    else
      _ -> :error
    end
  end

  defp luminance(_), do: :error

  defp channel_lum(c) when c <= 0.03928, do: c / 12.92
  defp channel_lum(c), do: :math.pow((c + 0.055) / 1.055, 2.4)

  # Aplica swap de texto branco -> escuro quando o fundo e claro demais
  defp apply_smart_contrast(content, brand) do
    primary = Map.get(brand, "color_primary") || ""
    dark = Map.get(brand, "color_dark") || ""

    content
    |> maybe_fix_contrast(primary)
    |> maybe_fix_contrast(dark)
  end

  defp maybe_fix_contrast(content, ""), do: content

  defp maybe_fix_contrast(content, hex) do
    if contrast_text(hex) == "#0A0E27" do
      # Fundo eh claro: texto branco precisa virar escuro
      swap_white_text_near_bg(content, hex, "#0A0E27")
    else
      content
    end
  end

  defp swap_white_text_near_bg(content, bg_hex, new_text) do
    bg = Regex.escape(bg_hex)

    # Pattern 1: HTML inline style — bg antes do color (ate ~300 chars dentro do mesmo style="...")
    p1 = ~r/(background(?:-color)?:\s*#{bg}[^"]{0,300}?color:\s*)(?:#FFFFFF|#ffffff|#fff|white)/i

    # Pattern 2: HTML inline style — color antes do bg
    p2 = ~r/(color:\s*)(?:#FFFFFF|#ffffff|#fff|white)([^"]{0,300}?background(?:-color)?:\s*#{bg})/i

    # Pattern 3: HTML attr bgcolor="..." em <td> com <a style="...color:#FFF" dentro (ate ~500 chars)
    p3 = ~r/(bgcolor="#{bg}"[^>]*>[^<]{0,200}<a[^>]*style="[^"]*color:\s*)(?:#FFFFFF|#ffffff|#fff|white)/i

    # Pattern 4: MJML <mj-button> com bg primary depois color="#FFFFFF"
    p4 = ~r/(<mj-button\b[^>]*background-color="#{bg}"[^>]*?\bcolor=)"(?:#FFFFFF|#ffffff|white)"/i

    # Pattern 5: MJML <mj-button> com color="#FFFFFF" antes do bg
    p5 = ~r/(<mj-button\b[^>]*?\bcolor=)"(?:#FFFFFF|#ffffff|white)"([^>]*background-color="#{bg}")/i

    content
    |> String.replace(p1, "\\1" <> new_text)
    |> String.replace(p2, "\\1" <> new_text <> "\\2")
    |> String.replace(p3, "\\1" <> new_text)
    |> String.replace(p4, "\\1\"" <> new_text <> "\"")
    |> String.replace(p5, "\\1\"" <> new_text <> "\"\\2")
  end
end
