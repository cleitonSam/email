defmodule KeilaWeb.MediaLive do
  @moduledoc """
  LiveView de biblioteca de imagens por projeto/academia.

  Permite upload (drag-drop ou click), grid de thumbnails, filtro por pasta
  (Logos / Fotos / Produtos / Hero / Avatares / Geral), e ações por imagem
  (copiar URL, alterar pasta, excluir).
  """
  use KeilaWeb, :live_view

  alias Keila.Media
  alias Keila.Media.Asset
  alias Keila.Integrations.ImageKit

  @max_size Media.max_file_size()

  @folders [
    %{slug: nil, label: "Todas"},
    %{slug: "geral", label: "Geral"},
    %{slug: "logos", label: "Logos"},
    %{slug: "fotos", label: "Fotos"},
    %{slug: "produtos", label: "Produtos"},
    %{slug: "hero", label: "Hero (capas)"},
    %{slug: "avatares", label: "Avatares"}
  ]

  @impl true
  def mount(_params, session, socket) do
    Gettext.put_locale(session["locale"])
    project = session["current_project"]
    user = session["current_user"]

    socket =
      socket
      |> assign(:current_project, project)
      |> assign(:current_user, user)
      |> assign(:folders, @folders)
      |> assign(:active_folder, nil)
      |> assign(:imagekit_configured?, ImageKit.configured?())
      |> assign(:counts, Media.count_by_folder(project.id))
      |> assign(:upload_error, nil)
      |> assign(:selected_asset, nil)
      |> assign(:assets, Media.list_assets(project.id))
      |> allow_upload(:image,
        accept: ~w(.png .jpg .jpeg .webp .gif .svg),
        max_entries: 10,
        max_file_size: @max_size,
        auto_upload: false
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(KeilaWeb.MediaView, "index_live.html", assigns)
  end

  @impl true
  def handle_event("select-folder", %{"folder" => folder}, socket) do
    folder = if folder == "", do: nil, else: folder

    assets = Media.list_assets(socket.assigns.current_project.id, folder: folder)
    {:noreply, assign(socket, active_folder: folder, assets: assets)}
  end

  def handle_event("validate-upload", _params, socket) do
    {:noreply, assign(socket, :upload_error, nil)}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("submit-upload", params, socket) do
    folder = params["folder"] || socket.assigns.active_folder || "geral"
    project_id = socket.assigns.current_project.id
    user_id = socket.assigns.current_user && socket.assigns.current_user.id

    results =
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        upload = %{
          path: path,
          filename: entry.client_name,
          content_type: entry.client_type
        }

        case Media.upload_and_create(project_id, upload,
               folder: folder,
               uploaded_by_user_id: user_id
             ) do
          {:ok, asset} -> {:ok, {:ok, asset}}
          {:error, reason} -> {:ok, {:error, reason, entry.client_name}}
        end
      end)

    {ok_count, errors} =
      Enum.reduce(results, {0, []}, fn
        {:ok, _asset}, {ok, errs} -> {ok + 1, errs}
        {:error, reason, name}, {ok, errs} -> {ok, [{name, reason} | errs]}
      end)

    socket =
      socket
      |> assign(:assets, Media.list_assets(project_id, folder: socket.assigns.active_folder))
      |> assign(:counts, Media.count_by_folder(project_id))
      |> put_upload_flash(ok_count, errors)

    {:noreply, socket}
  end

  def handle_event("select-asset", %{"id" => id}, socket) do
    {:noreply, assign(socket, :selected_asset, Media.get_asset(id))}
  end

  def handle_event("close-asset", _params, socket) do
    {:noreply, assign(socket, :selected_asset, nil)}
  end

  def handle_event("delete-asset", %{"id" => id}, socket) do
    project_id = socket.assigns.current_project.id

    case Media.get_asset(id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Imagem não encontrada (talvez já tenha sido removida).")}

      %Keila.Media.Asset{} = asset ->
        case Media.delete_asset(asset) do
          {:ok, _} ->
            socket =
              socket
              |> assign(:assets, Media.list_assets(project_id, folder: socket.assigns.active_folder))
              |> assign(:counts, Media.count_by_folder(project_id))
              |> assign(:selected_asset, nil)
              |> put_flash(:info, "Imagem excluída com sucesso.")

            {:noreply, socket}

          {:error, reason} ->
            require Logger
            Logger.error("[MediaLive] Erro ao excluir asset #{id}: #{inspect(reason)}")

            {:noreply,
             put_flash(socket, :error, "Erro ao excluir: #{inspect(reason)}. Tenta de novo.")}
        end
    end
  end

  def handle_event("update-asset", %{"asset" => params}, socket) do
    asset = socket.assigns.selected_asset

    case asset && Media.update_asset(asset, params) do
      {:ok, updated} ->
        socket =
          socket
          |> assign(
            :assets,
            Media.list_assets(socket.assigns.current_project.id,
              folder: socket.assigns.active_folder
            )
          )
          |> assign(:selected_asset, updated)
          |> put_flash(:info, "Imagem atualizada.")

        {:noreply, socket}

      _ ->
        {:noreply, put_flash(socket, :error, "Não consegui atualizar.")}
    end
  end

  defp put_upload_flash(socket, ok_count, []) when ok_count > 0,
    do:
      put_flash(socket, :info, "#{ok_count} #{plural(ok_count, "imagem", "imagens")} enviada(s).")

  defp put_upload_flash(socket, 0, [{name, reason} | _]),
    do: put_flash(socket, :error, "Falha em #{name}: #{reason}")

  defp put_upload_flash(socket, ok_count, errors),
    do:
      put_flash(
        socket,
        :error,
        "#{ok_count} ok, #{length(errors)} falharam: #{Enum.map_join(errors, ", ", fn {n, _} -> n end)}"
      )

  defp put_upload_flash(socket, _, _), do: socket

  defp plural(1, sing, _), do: sing
  defp plural(_, _, plur), do: plur

  @doc false
  def humanize_size(nil), do: "—"

  def humanize_size(bytes) when bytes < 1024, do: "#{bytes} B"

  def humanize_size(bytes) when bytes < 1024 * 1024,
    do: "#{Float.round(bytes / 1024, 1)} KB"

  def humanize_size(bytes), do: "#{Float.round(bytes / 1024 / 1024, 1)} MB"

  @doc false
  # SVG e GIF nao suportam transformacoes ImageKit — usa URL original
  def asset_thumb(%Asset{url: url, mime_type: mime}) when mime in ["image/svg+xml", "image/gif"], do: url
  def asset_thumb(%Asset{url: url}), do: ImageKit.thumbnail(url, w: 400, h: 400, c: "maintain_ratio")
end
