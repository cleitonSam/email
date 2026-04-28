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
end
