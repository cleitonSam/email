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

        if wants_json?(conn) do
          json(conn, %{ok: true, logo_url: asset.url})
        else
          conn
          |> put_flash(:info, "✓ Logo atualizado!")
          |> redirect(to: "/projects/#{project.id}/marca")
        end

      {:error, reason} ->
        if wants_json?(conn) do
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{ok: false, error: inspect(reason)})
        else
          conn
          |> put_flash(:error, "Erro: #{inspect(reason)}")
          |> redirect(to: "/projects/#{project.id}/marca")
        end
    end
  end

  # Cliente que envia Accept: application/json (ex: fetch do editor de email)
  # recebe JSON em vez de redirect. Mantém compat com o form HTML clássico.
  defp wants_json?(conn) do
    case get_req_header(conn, "accept") do
      [accept | _] -> String.contains?(accept, "application/json")
      _ -> false
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

  # URL pública servida quando não há logo ou o fetch da URL real falha.
  @placeholder_logo_url "https://placehold.co/280x88/0A0E27/FFFFFF/png?text=LOGO"

  @doc """
  Proxy público do logo da marca.

  Os emails apontam pra essa URL no app (`/b/:project_id/logo`) em vez da URL
  externa do ImageKit. O servidor busca a imagem pela rede (sem CORS, sem
  bloqueio de hotlink, sem "restrict unsigned URLs" do painel do ImageKit) e
  devolve os bytes pro cliente de email. Se não houver logo configurado ou o
  fetch falhar, redireciona pra um placeholder (assim o email nunca mostra
  ícone de imagem quebrada).
  """
  def public_logo(conn, %{"project_id" => project_id}) do
    try do
      case Keila.Projects.get_project(project_id) do
        nil ->
          serve_placeholder(conn)

        project ->
          brand = Brand.get(project)
          url = brand["logo_url"]

          if is_binary(url) and url != "" do
            case fetch_remote_image(url) do
              {:ok, body, content_type} ->
                conn
                |> put_resp_content_type(content_type)
                |> put_resp_header("cache-control", "public, max-age=86400")
                |> send_resp(200, body)

              :error ->
                serve_placeholder(conn)
            end
          else
            serve_placeholder(conn)
          end
      end
    rescue
      # Qualquer erro inesperado (ex: project_id em formato inválido faz o
      # cast do Ecto raise) cai no placeholder em vez de devolver 400/500.
      _ -> serve_placeholder(conn)
    end
  end

  defp serve_placeholder(conn) do
    conn
    |> put_resp_header("cache-control", "public, max-age=300")
    |> redirect(external: @placeholder_logo_url)
  end

  defp fetch_remote_image(url) do
    case HTTPoison.get(url, [{"User-Agent", "FluxoLogoProxy/1.0"}],
           recv_timeout: 10_000,
           timeout: 5_000,
           follow_redirect: true,
           max_redirect: 3
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} ->
        content_type =
          Enum.find_value(headers, "image/png", fn {k, v} ->
            if String.downcase(k) == "content-type", do: v
          end)

        {:ok, body, content_type}

      _ ->
        :error
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
