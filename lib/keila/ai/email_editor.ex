defmodule Keila.AI.EmailEditor do
  @moduledoc """
  Editor de emails com IA — recebe prompts em pt-BR e modifica/cria MJML.

  Modelo default: google/gemini-2.5-flash (~$0.005 por edição).
  """

  alias Keila.Integrations.OpenRouter

  @system_prompt_edit """
  Você é um editor especialista em MJML pra emails de academia em pt-BR.

  ⚠️ FORMATO OBRIGATÓRIO ⚠️
  Resposta DEVE começar com `<mjml>` e terminar com `</mjml>`.
  NÃO escreva NADA antes do `<mjml>`. NÃO escreva NADA depois do `</mjml>`.
  NÃO use markdown ```mjml ```. NÃO explique. APENAS o código MJML.

  ⚠️ COMPLETUDE OBRIGATÓRIA ⚠️
  Você DEVE retornar o MJML COMPLETO até o `</mjml>` final.
  NÃO TRUNQUE. NÃO use "...". NÃO escreva "// resto do código igual".
  Retorne TODO o MJML mesmo pra mudança pequena.
  Se faltar tokens, prefira encurtar conteúdo do email do que cortar a estrutura.

  REGRAS:
  1. Retorne APENAS código MJML válido — sem explicações, sem markdown.
  2. Preserve a estrutura `<mjml>...<mj-head>...</mj-head>...<mj-body>...</mj-body></mjml>`.
  3. Mantenha placeholders Liquid: `{{ first_name }}`, `{{ brand.color_primary }}`, `{{ brand.logo_url }}`, `{{ brand.name }}`, `{{ unidade }}`, `{{ link_agendamento }}`, `{{ link_unsubscribe }}`.
  4. NÃO mude `{{ brand.* }}` por valores hardcoded — são preenchidos dinamicamente.
  5. Mantenha classes css `display-mobile`, `h2-mobile`, `lead-mobile`, `cta-mobile`, `confetti`, `pill`, `number-mega`.
  6. Footer com `{{ brand.name }}`, `{{ brand.address }}` e `{{ link_unsubscribe }}`.
  7. Tom pt-BR informal, direto, energético.
  8. Mantenha media queries `@media only screen and (max-width: 480px)`.
  9. Width body = 600px. Padding lateral mobile = 24px.

  Retorne APENAS o MJML, começando com `<mjml>` e terminando com `</mjml>`.
  """

  @system_prompt_create """
  Você é designer de emails MJML pra academias. Cria templates lindos, modernos, mobile-first.

  REGRAS:
  1. APENAS código MJML válido (começa `<mjml>`, termina `</mjml>`), sem explicações.
  2. Width body = 600px. Padding = 24px.
  3. Tipografia: 'Inter', sans-serif.
  4. Use placeholders Liquid:
     - `{{ first_name }}` no greeting
     - `{{ brand.name }}` no footer
     - `{{ brand.logo_url | default: 'https://placehold.co/140x44/0A0E27/FFFFFF/png?text=ACADEMIA' }}`
     - `{{ brand.color_primary | default: '#FF5A1F' }}` em CTAs
     - `{{ brand.color_dark | default: '#0A0E27' }}` em sections escuras
     - `{{ link_unsubscribe }}` no footer
  5. Media queries `@media only screen and (max-width: 480px)`.
  6. Estrutura: HEADER + HERO + DARK section + STEPS/STATS + CTA + DARK FOOTER.
  7. Tom pt-BR informal, energético.
  8. CTAs `<mj-button>` border-radius 999px, weight 700.
  9. NÃO `-webkit-text-stroke` (quebra Outlook).
  """

  @doc "Edita um MJML existente baseado em instrução em linguagem natural."
  @spec edit(String.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def edit(mjml, instruction) when is_binary(mjml) and is_binary(instruction) do
    instruction = String.trim(instruction)

    if instruction == "" do
      {:error, "Diz o que você quer mudar."}
    else
      messages = [
        %{role: "system", content: @system_prompt_edit},
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

  @doc "Cria um MJML novo do zero baseado em descrição em linguagem natural."
  @spec create(String.t()) :: {:ok, String.t()} | {:error, term()}
  def create(description) when is_binary(description) do
    description = String.trim(description)

    if description == "" do
      {:error, "Descreve o email que você quer."}
    else
      messages = [
        %{role: "system", content: @system_prompt_create},
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

  defp validate_mjml(text) do
    text = String.trim(text)

    cond do
      not String.starts_with?(text, "<mjml") ->
        case String.split(text, "<mjml", parts: 2) do
          [_, rest] ->
            close_or_repair("<mjml" <> rest)

          _ ->
            {:error,
             "IA não retornou MJML válido. Tenta uma instrução mais clara — ex: 'troca a cor primária pra azul'."}
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
