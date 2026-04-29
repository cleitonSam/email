defmodule Keila.Integrations.OpenRouter do
  @moduledoc """
  Cliente HTTP do OpenRouter (https://openrouter.ai).

  OpenRouter é um proxy unificado pra Claude, GPT-4, Llama, DeepSeek, Gemini etc.
  Permite trocar modelo via config sem mexer no código.

  ## Configuração

  Em `config/runtime.exs`:

      config :keila, :openrouter,
        api_key: System.get_env("OPENROUTER_API_KEY"),
        default_model: System.get_env("OPENROUTER_MODEL") || "anthropic/claude-3.5-haiku"

  ## Modelos recomendados (por custo/qualidade pra MJML editing)

  - `google/gemini-2.5-flash` — ~$0.005/edição (RECOMENDADO: top inteligência + preço)
  - `openai/gpt-4.1-mini` — ~$0.004/edição (top OpenAI barato)
  - `google/gemini-2.0-flash` — ~$0.002/edição (mais barato)
  - `anthropic/claude-3.5-haiku` — ~$0.02/edição (mais caro mas + obediente)
  """

  require Logger

  @api_url "https://openrouter.ai/api/v1/chat/completions"
  @timeout 60_000

  @doc """
  Faz uma chamada chat completion no OpenRouter.

  ## Argumentos
  - `messages` — lista de %{role, content} (system, user, assistant)
  - `opts` — `:model` (override default), `:temperature` (0-1, default 0.3),
    `:max_tokens` (default 4000)

  ## Retorno
  - `{:ok, content_string}` com a resposta do modelo
  - `{:error, reason}` em qualquer falha
  """
  @spec chat_completion(list(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def chat_completion(messages, opts \\ []) when is_list(messages) do
    with {:ok, api_key} <- get_config(:api_key) do
      model = Keyword.get(opts, :model, default_model())

      body = %{
        model: model,
        messages: messages,
        temperature: Keyword.get(opts, :temperature, 0.3),
        max_tokens: Keyword.get(opts, :max_tokens, 4000)
      }

      headers = [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"},
        {"HTTP-Referer", "https://emailmkt.fluxodigitaltech.com.br"},
        {"X-Title", "Fluxo Email MKT"}
      ]

      Logger.debug("[OpenRouter] Calling #{model} with #{length(messages)} messages")

      case HTTPoison.post(@api_url, Jason.encode!(body), headers,
             recv_timeout: @timeout,
             timeout: 30_000
           ) do
        {:ok, %{status_code: 200, body: resp_body}} ->
          parse_response(resp_body)

        {:ok, %{status_code: status, body: resp_body}} ->
          Logger.error("[OpenRouter] HTTP #{status}: #{resp_body}")
          {:error, parse_error(resp_body, status)}

        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("[OpenRouter] Request failed: #{inspect(reason)}")
          {:error, "Falha de conexão com OpenRouter: #{inspect(reason)}"}
      end
    end
  end

  @doc """
  Verifica se OpenRouter está configurado (api_key presente).
  """
  @spec configured?() :: boolean()
  def configured? do
    case get_config_value(:api_key) do
      key when is_binary(key) and key != "" -> true
      _ -> false
    end
  end

  # --- Private ---

  defp parse_response(body) do
    case Jason.decode(body) do
      {:ok, %{"choices" => [%{"message" => %{"content" => content}} | _]}} ->
        {:ok, content}

      {:ok, %{"error" => %{"message" => msg}}} ->
        {:error, "OpenRouter: #{msg}"}

      {:ok, other} ->
        Logger.error("[OpenRouter] Resposta inesperada: #{inspect(other)}")
        {:error, "Resposta inválida do OpenRouter"}

      {:error, _} ->
        {:error, "Falha ao decodificar resposta"}
    end
  end

  defp parse_error(body, status) do
    case Jason.decode(body) do
      {:ok, %{"error" => %{"message" => msg}}} -> "OpenRouter: #{msg}"
      _ -> "OpenRouter retornou status #{status}"
    end
  end

  defp get_config(key) do
    case get_config_value(key) do
      nil ->
        {:error,
         "OpenRouter não configurado. Configure OPENROUTER_API_KEY no .env e reinicie."}

      "" ->
        {:error, "OpenRouter API key vazia."}

      val ->
        {:ok, val}
    end
  end

  defp get_config_value(key) do
    Application.get_env(:keila, :openrouter, [])
    |> Keyword.get(key)
  end

  defp default_model do
    get_config_value(:default_model) || "google/gemini-2.5-flash"
  end
end
