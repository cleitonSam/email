defmodule KeilaWeb.BrandController do
  @moduledoc """
  Tela "Minha Marca" — edita brand kit do projeto a qualquer momento.
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

  @doc "Pesquisa identidade da marca via IA."
  def research(conn, _params) do
    project = current_project(conn)
    brand = Brand.get(project)
    name = brand["name"] || ""

    if name == "" do
      conn
      |> put_flash(:error, "Coloca o nome da academia primeiro pra IA pesquisar.")
      |> redirect(to: "/projects/#{project.id}/marca")
    else
      case Keila.AI.BrandResearch.research(name, address: brand["address"] || "") do
        {:ok, profile} ->
          merged =
            brand
            |> Map.put("ai_profile", profile)
            |> Map.put("tone", profile["tone"] || brand["tone"])
            |> Map.put("keywords", profile["keywords"] || [])
            |> Map.put("target_audience", profile["target_audience"])
            |> Map.put("communication_style", profile["communication_style"])

          Brand.update(project.id, merged)

          conn
          |> put_flash(:info, "✓ Identidade pesquisada! A IA vai usar esse perfil pra editar emails.")
          |> redirect(to: "/projects/#{project.id}/marca")

        {:error, reason} ->
          conn
          |> put_flash(:error, "Erro: #{inspect(reason)}")
          |> redirect(to: "/projects/#{project.id}/marca")
      end
    end
  end

  defp get_extras(brand) do
    case Map.get(brand, "extra_colors") do
      list when is_list(list) -> list
      _ -> []
    end
  end

  defp current_project(conn), do: conn.assigns.current_project
end
