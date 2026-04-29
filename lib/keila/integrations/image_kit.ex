defmodule Keila.Integrations.ImageKit do
  @moduledoc """
  Cliente HTTP do ImageKit (https://imagekit.io).

  Usado para upload e gestão de imagens da biblioteca de mídia (`Keila.Media`).

  ## Configuração

  As credenciais são lidas de variáveis de ambiente em `config/runtime.exs`:

      config :keila, :imagekit,
        public_key: System.get_env("IMAGEKIT_PUBLIC_KEY"),
        private_key: System.get_env("IMAGEKIT_PRIVATE_KEY"),
        url_endpoint: System.get_env("IMAGEKIT_URL_ENDPOINT")

  > **Importante:** a `private_key` NUNCA deve ser exposta ao browser nem
  > comitada no repositório. Ela só é usada server-side pra autenticar
  > requisições à API REST do ImageKit.
  """

  require Logger

  @upload_url "https://upload.imagekit.io/api/v1/files/upload"
  @api_base "https://api.imagekit.io/v1"

  @doc """
  Faz upload de um arquivo pro ImageKit.

  ## Argumentos
  - `file_data` — bytes do arquivo (binary)
  - `filename` — nome do arquivo (ex: "logo.png")
  - `opts` — `:folder` (path no ImageKit, padrão "/"), `:tags` (lista de strings),
    `:use_unique_file_name` (bool, padrão true), `:content_type` (mime type)

  ## Retorno
  - `{:ok, response_map}` com `fileId`, `url`, `thumbnailUrl`, `size`, `width`, `height`
  - `{:error, reason}`
  """
  @spec upload_file(binary(), String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def upload_file(file_data, filename, opts \\ []) do
    with {:ok, private_key} <- get_config(:private_key) do
      folder = Keyword.get(opts, :folder, "/")
      use_unique = Keyword.get(opts, :use_unique_file_name, true) |> to_string()
      tags = Keyword.get(opts, :tags, []) |> Enum.join(",")
      mime = Keyword.get(opts, :content_type) || guess_mime_type(filename)

      boundary = "----FluxoBoundary" <> (:crypto.strong_rand_bytes(16) |> Base.encode16())

      body =
        [
          multipart_field(boundary, "fileName", filename),
          multipart_field(boundary, "folder", folder),
          multipart_field(boundary, "useUniqueFileName", use_unique),
          multipart_field(boundary, "tags", tags),
          multipart_file(boundary, "file", filename, mime, file_data),
          "--#{boundary}--\r\n"
        ]
        |> IO.iodata_to_binary()

      auth = "Basic " <> Base.encode64("#{private_key}:")

      headers = [
        {"Authorization", auth},
        {"Content-Type", "multipart/form-data; boundary=#{boundary}"}
      ]

      Logger.debug("[ImageKit] Uploading #{filename} (#{byte_size(file_data)} bytes) to #{folder}")

      case HTTPoison.post(@upload_url, body, headers,
             recv_timeout: 60_000,
             timeout: 30_000
           ) do
        {:ok, %{status_code: 200, body: resp_body}} ->
          case Jason.decode(resp_body) do
            {:ok, %{"fileId" => _} = data} ->
              Logger.info("[ImageKit] Upload OK — fileId=#{data["fileId"]}")
              {:ok, data}

            {:ok, other} ->
              Logger.error("[ImageKit] Resposta sem fileId: #{inspect(other)}")
              {:error, "Resposta inválida do ImageKit"}

            {:error, _} ->
              {:error, "Não consegui decodificar resposta do ImageKit"}
          end

        {:ok, %{status_code: status, body: resp_body}} ->
          Logger.error("[ImageKit] Upload falhou (#{status}): #{resp_body}")
          {:error, parse_error_message(resp_body, status)}

        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("[ImageKit] HTTP error: #{inspect(reason)}")
          {:error, "Falha de conexão com o ImageKit: #{inspect(reason)}"}
      end
    end
  end

  @doc """
  Remove um arquivo do ImageKit pelo fileId.

  Retorna `:ok` mesmo se o arquivo não existir mais (idempotente).
  """
  @spec delete_file(String.t()) :: :ok | {:error, term()}
  def delete_file(file_id) when is_binary(file_id) and file_id != "" do
    with {:ok, private_key} <- get_config(:private_key) do
      auth = "Basic " <> Base.encode64("#{private_key}:")
      url = "#{@api_base}/files/#{file_id}"
      headers = [{"Authorization", auth}]

      case HTTPoison.delete(url, headers, recv_timeout: 15_000) do
        {:ok, %{status_code: code}} when code in [204, 404] ->
          :ok

        {:ok, %{status_code: status, body: body}} ->
          Logger.warning("[ImageKit] Delete retornou #{status}: #{body}")
          {:error, "ImageKit retornou status #{status}"}

        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, "Falha de conexão: #{inspect(reason)}"}
      end
    end
  end

  def delete_file(_), do: :ok

  @doc """
  Gera URL com transformações on-the-fly do ImageKit.

  ## Exemplos
      iex> thumbnail("https://ik.imagekit.io/0jwoagmre/foto.jpg", w: 300, h: 300)
      "https://ik.imagekit.io/0jwoagmre/tr:w-300,h-300/foto.jpg"
  """
  @spec thumbnail(String.t(), keyword()) :: String.t()
  def thumbnail(url, transformations \\ []) when is_binary(url) do
    if transformations == [] do
      url
    else
      tr =
        transformations
        |> Enum.map(fn {k, v} -> "#{k}-#{v}" end)
        |> Enum.join(",")

      case String.split(url, "/", parts: 4) do
        [scheme, _empty, host, path] -> "#{scheme}//#{host}/tr:#{tr}/#{path}"
        _ -> url
      end
    end
  end

  @doc """
  Retorna a `public_key` e `url_endpoint` pra usar no frontend (browser).
  Nunca retorna a `private_key`.
  """
  @spec public_config() :: %{public_key: String.t() | nil, url_endpoint: String.t() | nil}
  def public_config do
    %{
      public_key: get_config_value(:public_key),
      url_endpoint: get_config_value(:url_endpoint)
    }
  end

  @doc """
  Verifica se a integração está configurada (todas as 3 chaves presentes).
  """
  @spec configured?() :: boolean()
  def configured? do
    config = Application.get_env(:keila, :imagekit, [])

    is_binary(config[:public_key]) and config[:public_key] != "" and
      is_binary(config[:private_key]) and config[:private_key] != "" and
      is_binary(config[:url_endpoint]) and config[:url_endpoint] != ""
  end

  # --- Multipart helpers ---

  defp multipart_field(boundary, name, value) do
    [
      "--#{boundary}\r\n",
      ~s|Content-Disposition: form-data; name="#{name}"\r\n|,
      "\r\n",
      to_string(value),
      "\r\n"
    ]
  end

  defp multipart_file(boundary, name, filename, mime, content) do
    [
      "--#{boundary}\r\n",
      ~s|Content-Disposition: form-data; name="#{name}"; filename="#{escape_filename(filename)}"\r\n|,
      "Content-Type: #{mime}\r\n",
      "\r\n",
      content,
      "\r\n"
    ]
  end

  defp escape_filename(filename) do
    filename
    |> String.replace("\"", "")
    |> String.replace("\r\n", " ")
  end

  # --- Config helpers ---

  defp get_config(key) do
    case get_config_value(key) do
      nil ->
        {:error,
         "ImageKit não configurado. Configure IMAGEKIT_#{key |> Atom.to_string() |> String.upcase()} no ambiente e reinicie o servidor."}

      "" ->
        {:error, "ImageKit: credencial vazia. Verifique IMAGEKIT_#{key |> Atom.to_string() |> String.upcase()}."}

      val ->
        {:ok, val}
    end
  end

  defp get_config_value(key) do
    Application.get_env(:keila, :imagekit, [])
    |> Keyword.get(key)
  end

  defp guess_mime_type(filename) do
    case Path.extname(filename) |> String.downcase() do
      ".png" -> "image/png"
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".webp" -> "image/webp"
      ".gif" -> "image/gif"
      ".svg" -> "image/svg+xml"
      _ -> "application/octet-stream"
    end
  end

  defp parse_error_message(body, status) do
    case Jason.decode(body) do
      {:ok, %{"message" => msg}} -> "ImageKit: #{msg}"
      {:ok, %{"error" => msg}} -> "ImageKit: #{msg}"
      _ -> "ImageKit retornou status #{status}"
    end
  end
end
