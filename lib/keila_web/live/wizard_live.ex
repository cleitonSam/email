defmodule KeilaWeb.WizardLive do
  @moduledoc """
  Wizard de onboarding inteligente — 4 steps em UMA tela:

  1. Nome da academia
  2. Upload do logo (vai pra ImageKit)
  3. Auto-extração de cores via Color Thief (JS no navegador)
  4. Preview + salvar

  Tudo numa LiveView só, com `assign(:step, 1..4)` controlando o flow.
  Sem mandar usuário pra outra página — tudo na mesma tela.
  """
  use KeilaWeb, :live_view

  alias Keila.Projects.Brand
  alias Keila.Media

  @max_logo_size 5 * 1024 * 1024

  @impl true
  def mount(_params, session, socket) do
    Gettext.put_locale(session["locale"])
    project = session["current_project"]
    user = session["current_user"]
    brand = Brand.get(project)

    socket =
      socket
      |> assign(:current_project, project)
      |> assign(:current_user, user)
      |> assign(:brand, brand)
      |> assign(:step, initial_step(brand))
      |> assign(:saving, false)
      |> assign(:imagekit_configured?, Keila.Integrations.ImageKit.configured?())
      |> allow_upload(:logo,
        accept: ~w(.png .jpg .jpeg .webp .svg),
        max_entries: 1,
        max_file_size: @max_logo_size,
        auto_upload: false
      )

    {:ok, socket}
  end

  defp initial_step(%{"name" => n}) when n in [nil, ""], do: 1
  defp initial_step(%{"logo_url" => l}) when l in [nil, ""], do: 2
  defp initial_step(%{"completed_at" => nil}), do: 3
  defp initial_step(_), do: 4

  @impl true
  def render(assigns) do
    Phoenix.View.render(KeilaWeb.WizardView, "setup_live.html", assigns)
  end

  # Step navigation
  @impl true
  def handle_event("go-step", %{"step" => step}, socket) do
    {:noreply, assign(socket, :step, String.to_integer(step))}
  end

  def handle_event("next-step", _params, socket) do
    {:noreply, assign(socket, :step, socket.assigns.step + 1)}
  end

  def handle_event("prev-step", _params, socket) do
    {:noreply, assign(socket, :step, max(1, socket.assigns.step - 1))}
  end

  # Step 1: Save name
  def handle_event("save-name", %{"brand" => %{"name" => name}}, socket) do
    name = String.trim(name)

    if name == "" do
      {:noreply, put_flash(socket, :error, "Conta o nome da sua academia")}
    else
      project_id = socket.assigns.current_project.id

      case Brand.update(project_id, %{"name" => name}) do
        {:ok, project} ->
          socket =
            socket
            |> assign(:brand, Brand.get(project))
            |> assign(:current_project, project)
            |> assign(:step, 2)

          {:noreply, socket}

        _ ->
          {:noreply, put_flash(socket, :error, "Erro ao salvar.")}
      end
    end
  end

  # Step 2: Upload logo (assíncrono pra evitar timeout do socket LiveView)
  def handle_event("validate-logo", _params, socket), do: {:noreply, socket}

  def handle_event("submit-logo", _params, socket) do
    project_id = socket.assigns.current_project.id
    user_id = socket.assigns.current_user && socket.assigns.current_user.id

    # Consome entries SINCRONAMENTE (lê arquivos do disco rapidinho — só I/O local)
    upload_data =
      consume_uploaded_entries(socket, :logo, fn meta, entry ->
        case File.read(meta.path) do
          {:ok, bytes} ->
            {:ok, %{bytes: bytes, filename: entry.client_name, content_type: entry.client_type}}

          _ ->
            {:postpone, :read_failed}
        end
      end)

    case upload_data do
      [%{bytes: _} = data | _] ->
        # Dispara upload pro ImageKit em background (pode levar 5-30s)
        live_view_pid = self()

        Task.start(fn ->
          result =
            Media.upload_and_create(project_id, data,
              folder: "logos",
              uploaded_by_user_id: user_id
            )

          send(live_view_pid, {:logo_upload_done, result})
        end)

        {:noreply,
         socket
         |> assign(:saving, true)
         |> put_flash(:info, "📤 Enviando logo... (pode levar uns segundos)")}

      _ ->
        {:noreply, put_flash(socket, :error, "Selecione um arquivo válido.")}
    end
  end

  @impl true
  def handle_info({:logo_upload_done, {:ok, asset}}, socket) do
    project_id = socket.assigns.current_project.id

    case Brand.update(project_id, %{"logo_url" => asset.url}) do
      {:ok, project} ->
        socket =
          socket
          |> assign(:brand, Brand.get(project))
          |> assign(:current_project, project)
          |> assign(:step, 3)
          |> assign(:saving, false)
          |> put_flash(:info, "✓ Logo enviado! Extraindo cores...")

        {:noreply, socket}

      _ ->
        {:noreply,
         socket
         |> assign(:saving, false)
         |> put_flash(:error, "Logo subiu mas falhou ao salvar URL.")}
    end
  end

  def handle_info({:logo_upload_done, {:error, reason}}, socket) do
    {:noreply,
     socket
     |> assign(:saving, false)
     |> put_flash(:error, "Falha no upload: #{reason}")}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  # Step 3: Cores extraídas via Color Thief — recebe via JS hook
  def handle_event(
        "save-colors",
        %{"primary" => primary, "dark" => dark, "accent" => accent},
        socket
      ) do
    project_id = socket.assigns.current_project.id

    case Brand.update(project_id, %{
           "color_primary" => primary,
           "color_dark" => dark,
           "color_accent" => accent
         }) do
      {:ok, project} ->
        socket =
          socket
          |> assign(:brand, Brand.get(project))
          |> assign(:current_project, project)
          |> assign(:step, 4)

        {:noreply, socket}

      _ ->
        {:noreply, put_flash(socket, :error, "Erro ao salvar cores.")}
    end
  end

  # Step 4: Finalizar setup
  def handle_event("finish", _params, socket) do
    project_id = socket.assigns.current_project.id

    case Brand.mark_completed(project_id) do
      {:ok, project} ->
        socket =
          socket
          |> assign(:brand, Brand.get(project))
          |> assign(:current_project, project)
          |> put_flash(:info, "🎉 Tudo pronto! Sua marca está aplicada nos templates.")
          |> redirect(to: "/projects/#{project.id}")

        {:noreply, socket}

      _ ->
        {:noreply, put_flash(socket, :error, "Erro ao finalizar setup.")}
    end
  end

  def handle_event("skip", _params, socket) do
    project_id = socket.assigns.current_project.id
    Brand.mark_completed(project_id)

    {:noreply, redirect(socket, to: "/projects/#{project_id}")}
  end
end
