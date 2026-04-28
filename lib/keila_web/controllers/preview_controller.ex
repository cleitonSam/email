defmodule KeilaWeb.PreviewController do
  @moduledoc """
  Serve os previews HTML compilados dos modelos MJML da biblioteca.

  Os HTMLs são lidos de `priv/email_templates/library/preview/` em
  COMPILE TIME e embutidos no binário da app. Isso garante que funcionam
  em dev, prod, Docker, releases — sem depender de filesystem em runtime.

  Aceita URLs no formato `/email-previews/01-boas-vindas-matricula` ou
  com extensão `.html`. Sanitiza o slug pra só aceitar alfanumérico + hífen.
  """
  use KeilaWeb, :controller

  @preview_glob "priv/email_templates/library/preview/*.html"
  @valid_slug ~r/^[a-zA-Z0-9_-]+$/

  # Lê todos os HTMLs em compile time e embute no módulo.
  # `@external_resource` invalida o cache se os arquivos mudarem.
  @previews (
    Path.wildcard(@preview_glob)
    |> Enum.map(fn path ->
      slug = Path.basename(path, ".html")
      content = File.read!(path)
      {slug, content}
    end)
    |> Map.new()
  )

  for path <- Path.wildcard(@preview_glob) do
    @external_resource path
  end

  @doc false
  def previews_loaded, do: Map.keys(@previews)

  def show(conn, %{"slug" => slug}) do
    slug =
      slug
      |> String.replace_suffix(".html", "")
      |> String.replace_suffix(".htm", "")

    cond do
      not Regex.match?(@valid_slug, slug) ->
        conn |> send_resp(400, "Slug inválido")

      true ->
        case Map.get(@previews, slug) do
          nil ->
            available = @previews |> Map.keys() |> Enum.sort() |> Enum.join(", ")

            conn
            |> put_resp_content_type("text/plain; charset=utf-8")
            |> send_resp(404, "Modelo \"#{slug}\" não encontrado.\n\nDisponíveis: #{available}")

          content ->
            conn
            |> put_resp_content_type("text/html; charset=utf-8")
            |> put_resp_header("x-frame-options", "SAMEORIGIN")
            |> put_resp_header("cache-control", "public, max-age=300")
            |> send_resp(200, content)
        end
    end
  end
end
