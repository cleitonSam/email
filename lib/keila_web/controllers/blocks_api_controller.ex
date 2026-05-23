defmodule KeilaWeb.BlocksApiController do
  @moduledoc """
  Endpoint JSON para o picker de blocos MJML reusaveis no editor.

  - `list/2` retorna metadata de todos os blocos disponiveis
  - `show/2` retorna o snippet MJML de um bloco especifico, ja com o
    brand aplicado (cores e logo da marca do projeto)
  """
  use KeilaWeb, :controller

  alias Keila.Templates.Blocks
  alias Keila.Templates.Library
  alias Keila.Projects.Brand

  def list(conn, _params) do
    json(conn, %{
      blocks: Blocks.list_blocks(),
      categories: Blocks.list_categories()
    })
  end

  def show(conn, %{"slug" => slug}) do
    case Blocks.load_mjml(slug) do
      {:ok, mjml} ->
        brand = Brand.get(conn.assigns.current_project)
        mjml_with_brand = Library.apply_brand(mjml, brand)
        json(conn, %{slug: slug, mjml: mjml_with_brand})

      {:error, _} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "block_not_found"})
    end
  end
end
