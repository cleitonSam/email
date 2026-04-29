defmodule Keila.AI.EmailEditor do
  @moduledoc """
  Editor de emails com IA — recebe prompts em pt-BR e modifica/cria MJML.

  Usa o cliente OpenRouter pra trocar modelo facilmente.
  Modelo default: Claude Haiku 3.5 (~$0.02 por edição).
  """

  alias Keila.Integrations.OpenRouter

  @system_prompt_edit """
  Você é um editor especialista em MJML (Mailjet Markup Language) pra emails de academia em pt-BR.

  ⚠️ FORMATO DE RESPOSTA OBRIGATÓRIO ⚠️
  Sua resposta DEVE começar exatamente com `<mjml>` e terminar exatamente com `</mjml>`.
  NÃO escreva NADA antes do `<mjml>`. NÃO escreva NADA depois do `</mjml>`.
  NÃO use markdown ```mjml ```. NÃO explique. NÃO comente. APENAS o código MJML.

  REGRAS ABSOLUTAS:
  1. Sempre retorne APENAS código MJML válido, NADA mais — sem explicações, sem markdown, sem ```mjml.
  2. Preserve a estrutura `<mjml>...<mj-head>...</mj-head>...<mj-body>...</mj-body></mjml>`.
  3. Mantenha TODOS os placeholders Liquid intactos: `{{ first_name }}`, `{{ brand.color_primary }}`, `{{ brand.logo_url }}`, `{{ brand.name }}`, `{{ unidade }}`, `{{ link_agendamento }}`, `{{ link_unsubscribe }}`, etc.
  4. NÃO mude `{{ brand.* }}` por valores hardcoded — eles são preenchidos dinamicamente.
  5. Mantenha as classes css `display-mobile`, `h2-mobile`, `lead-mobile`, `cta-mobile`, `confetti`, `pill`, `number-mega`.
  6. Mantenha o footer com `{{ brand.name }}`, `{{ brand.address }}` e `{{ link_unsubscribe }}`.
  7. Tom em pt-BR informal, direto, energético — voz de academia, sem jargão.
  8. Mantenha responsividade: media queries `@media only screen and (max-width: 480px)` no `<mj-style>`.
  9. Width do `<mj-body>` = 600px.
  10. Padding lateral = 24px (não 40px) pra mobile.

  PADRÃO DE ESTILO (mantenha):
  - Eyebrow: 11px, weight 700, letter-spacing 2.5px, uppercase, cor `{{ brand.color_primary }}`
  - Display heading: 48-56px, weight 800, line-height 1.05
  - Section dark: background `{{ brand.color_dark | default: '#0A0E27' }}` com texto branco
  - Section light: background `#FFF8F0` ou `#FFFFFF` com texto `#0A0E27`
  - CTA button: bordered pill (border-radius 999px), background `{{ brand.color_primary }}`, weight 700

  Retorne APENAS o MJML resultante, começando com `<mjml>` e terminando com `</mjml>`.
  """

  @system_prompt_create """
  Você é um designer de emails MJML pra academias. Cria templates lindos, modernos, mobile-first.

  REGRAS:
  1. Retorne APENAS código MJML válido (começa `<mjml>`, termina `</mjml>`), sem explicações.
  2. Width body = 600px. Padding lateral = 24px.
  3. Tipografia: `'Inter', -apple-system, BlinkMacSystemFont, sans-serif`.
  4. Sempre use placeholders Liquid:
     - `{{ first_name }}` no greeting
     - `{{ brand.name }}` no footer
     - `{{ brand.logo_url | default: 'https://placehold.co/140x44/0A0E27/FFFFFF/png?text=ACADEMIA' }}` no header
     - `{{ brand.color_primary | default: '#FF5A1F' }}` em CTAs e accents
     - `{{ brand.color_dark | default: '#0A0E27' }}` em sections escuras
     - `{{ brand.address }}` no footer
     - `{{ link_unsubscribe }}` no footer (descadastrar)
  5. Inclua media queries em `<mj-style>` com `@media only screen and (max-width: 480px)` reduzindo display fonts.
  6. Inclua `mj-class` definições no `<mj-attributes>` pra eyebrow/display/h2/lead.
  7. Estrutura típica:
     - HEADER com logo
     - HERO image opcional
     - DARK section com display heading + lead text + CTA
     - 3 STEPS ou STATS BAR
     - TESTIMONIAL ou SOCIAL PROOF (opcional)
     - CTA FINAL section
     - DARK FOOTER com brand info + descadastrar
  8. Tom: pt-BR informal, energético, direto. Voz de academia.
  9. CTAs: `<mj-button>` com `border-radius: 999px`, `inner-padding: 18px 36px`, weight 700.
  10. NÃO use `-webkit-text-stroke` (quebra em Outlook).
  11. NÃO use `mj-spacer` consecutivo — use `padding` ou `mj-image` direto.
  """

  @doc """
  Edita um MJML existente baseado em instrução em linguagem natural.

  ## Exemplos
      iex> EmailEditor.edit("<mjml>...</mjml>", "deixa o tom mais informal")
      {:ok, "<mjml>...modified...</mjml>"}
  """
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

      with {:ok, response} <- OpenRouter.chat_completion(messages, temperature: 0.3) do
        validate_mjml(extract_mjml(response))
      end
    end
  end

  @doc """
  Cria um MJML novo do zero baseado em descrição em linguagem natural.

  ## Exemplos
      iex> EmailEditor.create("email anunciando Black Friday com 30% off na anuidade")
      {:ok, "<mjml>...</mjml>"}
  """
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

      with {:ok, response} <- OpenRouter.chat_completion(messages, temperature: 0.6, max_tokens: 6000) do
        validate_mjml(extract_mjml(response))
      end
    end
  end

  # Valida que o resultado começa com <mjml> e termina com </mjml>.
  # Se a IA retornou texto antes/depois ou MJML quebrado, retorna erro.
  defp validate_mjml(text) do
    text = String.trim(text)

    cond do
      not S