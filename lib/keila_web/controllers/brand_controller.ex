defmodule KeilaWeb.BrandController do
  @moduledoc """
  Tela "Minha Marca" — edita brand kit do projeto a qualquer momento.

  Permite editar nome, logo, cores principais (primary, dark, accent) e
  adicionar cores extras (color_1, color_2, etc).
  """
  use KeilaWeb, :controller

  alias Keila.Projects.Brand
  alias Keila.Media

  def show(conn, _params) do
    project = current_project(conn)
    brand = Brand.get(project)

    conn
    |> assign(:brand, brand)
    |> assign(:extra_colors, get_extras(brand))
    |> render("show.html")
  end

  def update(conn, %{"brand" => params}) do
    project = current_project(conn)

    # Junta cores extras (color_1, color_2, ...) num só "extra_colors" array
    extras =
      params
      |> Enum.filter(fn {k, _} -> String.starts_with?(k, "extra_") end)
      |> Enum.map(fn {_, v} -> v end)
      |> Enum.reject(&(&1 in [nil, ""]))

    main_params =
      params
      |> Map.take(["name", "color_primary", "color_dark", "color_accent", "whatsapp_url", "address"])
      |> Map.put("extra_colors", extras)

    case Brand.update(project.id, main_params) do
      {:ok, _project} ->
        conn
        |> put_flash(:info, "✓ Marca atualizada! Os modelos de email já estão usando as novas cores.")
        |> redirect(to: "/projects/#{project.id}/marca")

      {:error, _} ->
        conn
        |> put_flash(:error, "Erro ao salvar.")
        |> redirect(to: "/projects/#{project.id}/marca")
    end
  end

  def upload_logo(conn, %{"logo" => %Plug.Upload{} = upload}) do
    project = current_project(conn)
    user = conn.assigns[:current_user]

    case Media.upload_and_create(project.id, upload,
           folder: "logos",
           uploaded_by_user_id: user && user.id
         ) do
      {:ok, asset} ->
        Brand.update(project.id, %{"logo_url" => asset.url})

        conn
        |> put_flash(:info, "✓ Logo atualizado!")
        |> redirect(to: "/projects/#{project.id}/marca")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Erro: #{inspect(reason)}")
        |> redirect(to: "/projects/#{project.id}/marca")
    end
  end

  def upload_logo(conn, _params) do
    project = current_project(conn)

    conn
    |> put_flash(:error, "Selecione um logo.")
    |> redirect(to: "/projects/#{project.id}/marca")
  end

  defp get_extras(brand) do
    case Map.get(brand, "extra_colors") do
      list when is_list(list) -> list
      _ -> []
    end
  end

  defp current_project(conn), do: conn.assigns.current_project
end
