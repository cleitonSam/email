defmodule Keila.AI.EmailEditor do
  @moduledoc """
  Editor de emails com IA — recebe prompts em pt-BR e modifica/cria MJML.

  Modelo default: google/gemini-2.5-flash (~$0.005 por edição).
  """

  alias Keila.Integrations.OpenRouter

  @doc """
  Edita um MJML existente baseado em instrução em linguagem natural.

  ## Argumentos
  - `mjml` — código MJML atual
  - `instruction` — o que mudar (pt-BR)
  - `brand` — opcional: mapa do brand kit pra IA respeitar cores/tom
  """
  @spec edit(String.t(), String.t(), map() | nil) :: {:ok, String.t()} | {:error, term()}
  def edit(mjml, instruction, brand \\ nil)
      when is_binary(mjml) and is_binary(instruction) do
    instruction = String.trim(instruction)

    if instruction == "" do
      {:error, "Diz o que você quer mudar."}
    else
      messages = [
        %{role: "system", content: build_edit_prompt(brand)},
        %{
          role: "user",
          content: """
          MJML ATUAL:
          ```mjml
          #{mjml}
          ```

          O QUE EU QUERO MUDAR:
          #{instruction}

          Retorna o MJML completo modificado.
          """
        }
      ]

      with {:ok, response} <-
             OpenRouter.chat_completion(messages, temperature: 0.3, max_tokens: 12000) do
        validate_mjml(extract_mjml(response))
      end
    end
  end

  @doc "Cria um MJML novo do zero baseado em descrição."
  @spec create(String.t(), map() | nil) :: {:ok, String.t()} | {:error, term()}
  def create(description, brand \\ nil) when is_binary(description) do
    description = String.trim(description)

    if description == "" do
      {:error, "Descreve o email que você quer."}
    else
      messages = [
        %{role: "system", content: build_create_prompt(brand)},
        %{
          role: "user",
          content: """
          Cria um email MJML pra academia com esse propósito:

          #{description}

          Retorna só o MJML completo, sem explicação.
          """
        }
      ]

      with {:ok, response} <-
             OpenRouter.chat_completion(messages, temperature: 0.6, max_tokens: 12000) do
        validate_mjml(extract_mjml(response))
      end
    end
  end

  # Constrói prompt de edit injetando cores e tom da marca
  defp build_edit_prompt(brand) do
    brand_block = brand_context_block(brand)

    """
    Você é um editor especialista em MJML pra emails de academia em pt-BR.

    #{brand_block}

    ⚠️ FORMATO OBRIGATÓRIO ⚠️
    Resposta DEVE começar com `<mjml>` e terminar com `</mjml>`.
    NÃO escreva NADA antes do `<mjml>`. NÃO escreva NADA depois do `</mjml>`.
    NÃO use markdown ```mjml ```. NÃO explique. APENAS o código MJML.

    ⚠️ COMPLETUDE OBRIGATÓRIA ⚠️
    Você DEVE retornar o MJML COMPLETO até o `</mjml>` final.
    NÃO TRUNQUE. NÃO use "...". Retorne TODO o MJML mesmo pra mudança pequena.

    ⚠️ CORES DA MARCA — REGRA RÍGIDA ⚠️
    Use APENAS as cores que estão no brand kit acima. NÃO INVENTE cores.
    Se a marca tem verde+branco, NÃO use azul/laranja/cinza colorido.
    Sempre use os placeholders Liquid `{{ brand.color_primary }}`,
    `{{ brand.color_dark }}`, `{{ brand.color_accent }}` e as extras
    `{{ brand.extra_colors[N] }}` quando precisar de outra cor.
    Se a instrução do usuário pedir uma cor que não está na marca, ignore
    e use a cor da marca mais próxima do propósito.

    REGRAS:
    1. Retorne APENAS código MJML válido — sem explicações, sem markdown.
    2. Preserve a estrutura `<mjml>...<mj-head>...</mj-head>...<mj-body>...</mj-body></mjml>`.
    3. Mantenha placeholders Liquid: `{{ first_name }}`, `{{ brand.color_primary }}`, `{{ brand.logo_url }}`, `{{ brand.name }}`, `{{ unidade }}`, `{{ link_agendamento }}`, `{{ link_unsubscribe }}`.
    4. NÃO mude `{{ brand.* }}` por valores hardcoded.
    5. Mantenha classes css `display-mobile`, `h2-mobile`, `lead-mobile`, `cta-mobile`, `confetti`, `pill`, `number-mega`.
    6. Footer com `{{ brand.name }}`, `{{ brand.address }}` e `{{ link_unsubscribe }}`.
    7. Tom da marca: respeite as instruções do brand kit. Se não tiver, use pt-BR informal e direto.
    8. Mantenha media queries `@media only screen and (max-width: 480px)`.
    9. Width body = 600px. Padding lateral mobile = 24px.

    Retorne APENAS o MJML, começando com `<mjml>` e terminando com `</mjml>`.
    """
  end

  defp build_create_prompt(brand) do
    brand_block = brand_context_block(brand)

    """
    Você é designer de emails MJML pra academias. Cria templates lindos, modernos, mobile-first.

    #{brand_block}

    REGRAS:
    1. APENAS código MJML válido (começa `<mjml>`, termina `</mjml>`), sem explicações.
    2. Width body = 600px. Padding = 24px.
    3. Tipografia: 'Inter', sans-serif.
    4. Use APENAS cores da marca acima — NÃO invente cores que não estão no brand kit.
    5. Use placeholders Liquid:
       - `{{ first_name }}` no greeting
       - `{{ brand.name }}` no footer
       - `{{ brand.logo_url | default: 'https://placehold.co/140x44/0A0E27/FFFFFF/png?text=ACADEMIA' }}`
       - `{{ brand.color_primary | default: '#FF5A1F' }}` em CTAs
       - `{{ brand.color_dark | default: '#0A0E27' }}` em sections escuras
       - `{{ link_unsubscribe }}` no footer
    6. Media queries `@media only screen and (max-width: 480px)`.
    7. Estrutura: HEADER + HERO + DARK section + STEPS/STATS + CTA + DARK FOOTER.
    8. CTAs `<mj-button>` border-radius 999px, weight 700.
    9. NÃO `-webkit-text-stroke` (quebra Outlook).
    10. Tom da marca: respeite o brand kit. Se não tiver, use pt-BR energético.
    """
  end

  # Bloco com contexto do brand kit (cores, tom, palavras)
  defp brand_context_block(nil), do: ""

  defp brand_context_block(brand) when is_map(brand) do
    name = brand["name"] || "—"
    primary = brand["color_primary"] || "—"
    dark = brand["color_dark"] || "—"
    accent = brand["color_accent"] || "—"
    extras = brand["extra_colors"] || []
    extras_str = if extras == [], do: "(nenhuma)", else: Enum.join(extras, ", ")
    tone = brand["tone"] || "—"
    target = brand["target_audience"] || "—"
    style = brand["communication_style"] || "—"
    keywords = brand["keywords"] || []
    keywords_str = if keywords == [], do: "—", else: Enum.join(keywords, ", ")

    """
    ━━━━━━━━━━ BRAND KIT — USAR À RISCA ━━━━━━━━━━
    Marca: #{name}

    🎨 PALETA DE CORES (USE APENAS ESSAS):
    • Primária: #{primary}  (placeholder: {{ brand.color_primary }})
    • Escura: #{dark}  (placeholder: {{ brand.color_dark }})
    • Accent: #{accent}  (placeholder: {{ brand.color_accent }})
    • Extras: #{extras_str}

    NÃO USE NENHUMA OUTRA COR. Se a marca é verde, NÃO use azul.
    Se for laranja+preto, NÃO use roxo/cinza-azulado.

    📣 TOM DE VOZ: #{tone}
    🎯 PÚBLICO: #{target}
    💬 ESTILO DE COMUNICAÇÃO: #{style}
    🔑 PALAVRAS-CHAVE DA MARCA: #{keywords_str}
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    """
  end

  defp validate_mjml(text) do
    text = String.trim(text)

    cond do
      not String.starts_with?(text, "<mjml") ->
        case String.split(text, "<mjml", parts: 2) do
          [_, rest] -> close_or_repair("<mjml" <> rest)
          _ -> {:error, "IA não retornou MJML válido. Tenta uma instrução mais clara."}
        end

      true ->
        close_or_repair(text)
    end
  end

  defp close_or_repair(text) do
    cond do
      String.ends_with?(text, "</mjml>") ->
        {:ok, text}

      String.contains?(text, "</mjml>") ->
        [final, _] = String.split(text, "</mjml>", parts: 2)
        {:ok, final <> "</mjml>"}

      String.contains?(text, "</mj-body>") ->
        [final, _] = String.split(text, "</mj-body>", parts: 2)
        {:ok, final <> "</mj-body>\n</mjml>"}

      true ->
        case repair_truncated(text) do
          {:ok, repaired} -> {:ok, repaired}
          :no_repair -> {:error, "IA retornou MJML muito incompleto. Tenta uma instrução mais simples."}
        end
    end
  end

  defp repair_truncated(text) do
    parts = String.split(text, "</mj-section>")

    if length(parts) >= 2 do
      base = parts |> Enum.drop(-1) |> Enum.join("</mj-section>")
      {:ok, base <> "</mj-section>\n</mj-body>\n</mjml>"}
    else
      :no_repair
    end
  end

  defp extract_mjml(text) do
    text = String.trim(text)

    cond do
      String.contains?(text, "```mjml") ->
        text
        |> String.split("```mjml", parts: 2)
        |> List.last()
        |> String.split("```", parts: 2)
        |> List.first()
        |> String.trim()

      String.contains?(text, "```") ->
        text
        |> String.split("```", parts: 3)
        |> Enum.at(1, "")
        |> String.trim()

      true ->
        text
    end
  end
end
