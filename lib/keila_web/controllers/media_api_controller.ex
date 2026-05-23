defmodule KeilaWeb.MediaApiController do
  @moduledoc """
  Endpoint JSON para o picker de imagens INLINE no editor MJML.
  Retorna a lista de imagens do projeto pra um modal que aparece
  na mesma tela do editor (sem mandar o usuário pra outra página).
  """
  use KeilaWeb, :controller

  alias Keila.Media

  def list(conn, _params) do
    project = conn.assigns.current_project

    assets =
      project.id
      |> Media.list_assets()
      |> Enum.map(fn a ->
        %{
          id: a.id,
          url: a.url,
          thumbnail_url: a.thumbnail_url || a.url,
          filename: a.filename,
          folder: a.folder,
          width: a.width,
          height: a.height
        }
      end)

    json(conn, %{assets: assets, count: length(assets)})
  end

  @doc """
  Upload inline de imagem direto do editor (Fase 4).
  Espera multipart com campo "file". Salva via Media.upload_and_create/3
  com folder "inline" e retorna {url, filename} pra UI preencher o campo.
  """
  def upload(conn, params) do
    project = conn.assigns.current_project
    user_id = conn.assigns[:current_user] && conn.assigns.current_user.id

    case params["file"] do
      %Plug.Upload{} = upload ->
        case Media.upload_and_create(project.id, upload,
               folder: "inline",
               uploaded_by_user_id: user_id
             ) do
          {:ok, asset} ->
            json(conn, %{ok: true, url: asset.url, filename: asset.filename})

          {:error, reason} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{ok: false, error: format_error(reason)})
        end

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{ok: false, error: "Arquivo não enviado"})
    end
  end

  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(reason), do: inspect(reason)
end
