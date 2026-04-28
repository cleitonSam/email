defmodule KeilaWeb.PreviewController do
  @moduledoc """
  Serve os previews HTML compilados dos modelos MJML da biblioteca.

  Os arquivos ficam em `priv/email_templates/library/preview/` (versionados
  no git). Esta rota é PÚBLICA — qualquer pessoa pode ver os previews dos
  templates, eles não contêm dados de cliente.

  Aceita URLs no formato `/email-previews/01-boas-vindas-matricula` ou
  com extensão `.html`. Sanitiza o slug pra só aceitar alfanumérico + hífen
  (anti path traversal).
  """
  use KeilaWeb, :controller

  @preview_dir "priv/email_templates/library/preview"
  @valid_slug ~r/^[a-zA-Z0-9_-]+$/

  def show(conn, %{"slug" => slug}) do
    slug =
      slug
      |> String.replace_suffix(".html", "")
      |> String.replace_suffix(".htm", "")

    cond do
      not Regex.match?(@valid_slug, slug) ->
        conn |> send_resp(400, "Slug inválido")

      true ->
        path =
          Path.join([
            Application.app_dir(:keila, @preview_dir),
            "#{slug}.html"
          ])

        if File.exists?(path) do
          conn
          |> put_resp_content_type("text/html; charset=utf-8")
          |> put_resp_header("x-frame-options", "SAMEORIGIN")
          |> put_resp_header("cache-control", "public, max-age=300")
          |> send_file(200, path)
        else
          conn |> send_resp(404, "Modelo não encontrado: #{slug}")
        end
    end
  end
end
