defmodule Keila.AI.BrandResearch do
  @moduledoc """
  Pesquisa identidade de marca via IA. Recebe nome + endereço da academia
  e tenta inferir tom de voz, palavras-chave, público-alvo, posicionamento.
  """

  require Logger
  alias Keila.Integrations.OpenRouter

  @system_prompt """
  Você é especialista em branding e marketing pra academias brasileiras.
  Recebe o nome (e opcionalmente endereço) de uma academia e retorna um
  perfil de marca em JSON.

  Retorne APENAS um objeto JSON válido (sem markdown, sem texto extra)
  com os campos:

  {
    "tone": "string curta — tom de voz (ex: 'energético, jovem e descontraído')",
    "personality_traits": ["lista de 3-5 adjetivos da personalidade"],
    "target_audience": "público-alvo principal em 1 frase",
    "value_proposition": "proposta de valor em 1 frase",
    "keywords": ["lista de 5-10 palavras-chave da marca"],
    "do_not_use": ["lista de termos a evitar (ex: 'gordura', 'gordo')"],
    "communication_style": "estilo de comunicação preferido (ex: 'mensagens diretas, com emojis, chamando o aluno pelo primeiro nome')",
    "content_pillars": ["lista de 3-5 pilares de conteúdo (ex: 'transformação', 'comunidade', 'saúde')"]
  }

  Se não tiver informação específica sobre a academia, use defaults
  inteligentes baseados no contexto: academia brasileira, público
  variado (18-50 anos), tom motivacional e direto.

  NÃO inclua explicações. APENAS o JSON.
  """

  @doc """
  Pesquisa identidade da marca dado o nome (e opcionalmente address).

  Retorna {:ok, map} com os campos do perfil ou {:error, reason}.
  """
  @spec research(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def research(brand_name, opts \\ []) when is_binary(brand_name) do
    name = String.trim(brand_name)

    if name == "" do
      {:error, "Nome da academia é obrigatório."}
    else
      address = Keyword.get(opts, :address, "")
      city = Keyword.get(opts, :city, "")

      user_content = """
      Nome da academia: #{name}
      #{if address != "", do: "Endereço: #{address}", else: ""}
      #{if city != "", do: "Cidade: #{city}", else: ""}

      Pesquise/infera a identidade desta marca e retorne o JSON conforme instruções.
      """

      messages = [
        %{role: "system", content: @system_prompt},
        %{role: "user", content: user_content}
      ]

      with {:ok, response} <-
             OpenRouter.chat_completion(messages, temperature: 0.5, max_tokens: 2000),
           {:ok, json} <- parse_json(response) do
        {:ok, json}
      else
        {:error, reason} ->
          Logger.error("[BrandResearch] failed: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp parse_json(text) do
    cleaned =
      text
      |> String.trim()
      |> strip_markdown_fence()

    case Jason.decode(cleaned) do
      {:ok, map} when is_map(map) -> {:ok, map}
      {:ok, _} -> {:error, "IA não retornou um objeto JSON."}
      {:error, _} -> {:error, "IA retornou JSON inválido. Tenta de novo."}
    end
  end

  defp strip_markdown_fence(text) do
    cond do
      String.contains?(text, "```json") ->
        text
        |> String.split("```json", parts: 2)
        |> List.last()
        |> String.split("```", parts: 2)
        |> List.first()
        |> String.trim()

      String.contains?(text, "```") ->
        text
        |> String.split("```", parts: 3)
        |> Enum.at(1, text)
        |> String.trim()

      true ->
        text
    end
  end
end
