defmodule KeilaWeb.UnitsLive do
  @moduledoc """
  Tela "Minhas Academias" — gerenciamento de múltiplas unidades EVO por projeto.

  Cada academia é exibida como card grande com:
  - Nome
  - Bolinha verde/vermelha indicando conectividade
  - Última sincronização
  - Menu de ações (editar / desativar / excluir)

  Wizard de cadastro com APENAS 3 campos: Nome, Login EVO, Senha EVO.
  Botão "Testar conexão" valida na hora antes de salvar.
  """
  use KeilaWeb, :live_view

  alias Keila.Integrations.Evo.Units
  alias Keila.Integrations.Evo.Unit

  @impl true
  def mount(_params, session, socket) do
    Gettext.put_locale(session["locale"])
    project = session["current_project"]

    socket =
      socket
      |> assign(:current_project, project)
      |> assign(:units, Units.list_units(project.id))
      |> assign(:show_form, false)
      |> assign(:editing, nil)
      |> assign(:form_changeset, empty_changeset(project.id))
      |> assign(:test_result, nil)
      |> assign(:testing, false)
      |> assign(:syncing, false)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(KeilaWeb.UnitsView, "index_live.html", assigns)
  end

  @impl true
  def handle_event("new-unit", _params, socket) do
    socket =
      socket
      |> assign(:show_form, true)
      |> assign(:editing, nil)
      |> assign(:form_changeset, empty_changeset(socket.assigns.current_project.id))
      |> assign(:test_result, nil)

    {:noreply, socket}
  end

  def handle_event("edit-unit", %{"id" => id}, socket) do
    unit = Units.get_unit(id)

    socket =
      socket
      |> assign(:show_form, true)
      |> assign(:editing, unit)
      |> assign(:form_changeset, Unit.update_changeset(unit, %{}))
      |> assign(:test_result, nil)

    {:noreply, socket}
  end

  def handle_event("close-form", _params, socket) do
    {:noreply, assign(socket, show_form: false, editing: nil, test_result: nil)}
  end

  def handle_event("validate-form", %{"unit" => params}, socket) do
    changeset =
      case socket.assigns.editing do
        nil -> Unit.creation_changeset(Map.put(params, "project_id", socket.assigns.current_project.id))
        unit -> Unit.update_changeset(unit, params)
      end
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form_changeset: changeset, test_result: nil)}
  end

  def handle_event("save-unit", %{"unit" => params}, socket) do
    project_id = socket.assigns.current_project.id
    dns = String.trim(params["evo_dns"] || "")
    secret = String.trim(params["evo_secret_key"] || "")

    # Testa conexão antes de salvar (UX mais segura — não salva credencial errada)
    test_unit = %Unit{
      evo_dns: dns,
      evo_secret_key: secret
    }

    case Units.test_connection(test_unit) do
      :ok ->
        # Use trimmed params for saving as well
        params = Map.merge(params, %{"evo_dns" => dns, "evo_secret_key" => secret})
        do_save(socket, params, project_id)

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:test_result, {:error, "Não consegui conectar: #{reason}. Confere o login e a senha."})
         |> put_flash(:error, "Credenciais não funcionaram. Confere o login e a senha.")}
    end
  end

  defp do_save(socket, params, project_id) do
    result =
      case socket.assigns.editing do
        nil ->
          params = Map.put(params, "project_id", project_id)
          Units.create_unit(params)

        unit ->
          Units.update_unit(unit, params)
      end

    case result do
      {:ok, _unit} ->
        socket =
          socket
          |> assign(:units, Units.list_units(project_id))
          |> assign(:show_form, false)
          |> assign(:editing, nil)
          |> put_flash(:info, "Academia salva e conectada!")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form_changeset: changeset)}
    end
  end

  def handle_event("toggle-active", %{"id" => id}, socket) do
    unit = Units.get_unit(id)

    case unit && Units.update_unit(unit, %{active: !unit.active}) do
      {:ok, _} ->
        {:noreply, assign(socket, :units, Units.list_units(socket.assigns.current_project.id))}

      _ ->
        {:noreply, put_flash(socket, :error, "Não consegui alterar.")}
    end
  end

  def handle_event("delete-unit", %{"id" => id}, socket) do
    unit = Units.get_unit(id)

    case unit && Units.delete_unit(unit) do
      {:ok, _} ->
        socket =
          socket
          |> assign(:units, Units.list_units(socket.assigns.current_project.id))
          |> put_flash(:info, "Academia removida.")

        {:noreply, socket}

      _ ->
        {:noreply, put_flash(socket, :error, "Não consegui remover.")}
    end
  end

  def handle_event("sync-now", _params, socket) do
    project_id = socket.assigns.current_project.id
    send(self(), {:do_sync, project_id})

    {:noreply,
     socket
     |> put_flash(:info, "Sincronizando... Pode levar alguns segundos.")
     |> assign(:syncing, true)}
  end

  @impl true
  def handle_info({:do_sync, project_id}, socket) do
    # Dispara sync síncrono — pega oportunidades + alunos de todas unidades ativas
    Keila.Automations.Workers.SyncWorker.sync_project(project_id)

    {:noreply,
     socket
     |> assign(:units, Units.list_units(project_id))
     |> assign(:syncing, false)
     |> put_flash(:info, "Sincronização concluída! Vai em \"Contacts\" pra ver os leads importados.")}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp empty_changeset(project_id) do
    %Unit{}
    |> Ecto.Changeset.change(%{
      project_id: project_id,
      name: "",
      evo_dns: "",
      evo_secret_key: "",
      active: true
    })
  end

  @doc false
  def status_color(%Unit{active: false}), do: "bg-gray-500"
  def status_color(%Unit{last_sync_status: "ok"}), do: "bg-emerald-500"
  def status_color(%Unit{last_sync_status: "error"}), do: "bg-red-500"
  def status_color(%Unit{}), do: "bg-amber-500"

  @doc false
  def status_label(%Unit{active: false}), do: "Desativada"
  def status_label(%Unit{last_sync_status: "ok"}), do: "Conectada"
  def status_label(%Unit{last_sync_status: "error"}), do: "Erro"
  def status_label(%Unit{last_sync_at: nil}), do: "Nunca sincronizou"
  def status_label(%Unit{}), do: "Pendente"

  @doc false
  def humanize_sync_at(nil), do: "Nunca sincronizado"

  def humanize_sync_at(%DateTime{} = dt) do
    diff = DateTime.diff(DateTime.utc_now(), dt, :second)

    cond do
      diff < 60 -> "Agora há pouco"
      diff < 3600 -> "Há #{div(diff, 60)} min"
      diff < 86_400 -> "Há #{div(diff, 3600)}h"
      true -> "Há #{div(diff, 86_400)} dia(s)"
    end
  end
end
