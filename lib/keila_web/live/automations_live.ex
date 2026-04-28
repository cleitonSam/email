defmodule KeilaWeb.AutomationsLive do
  @moduledoc """
  Tela "Automações" — receitas prontas + automações ativas.

  Layout:
  1. Topo: lista de automações ATIVAS no projeto (cards com nome, status, total enviado, botão pausar/excluir)
  2. Embaixo: 4 cards de RECEITAS PRONTAS pra ativar com 1 clique (escolhe unidade no dropdown)
  """
  use KeilaWeb, :live_view

  alias Keila.Automations
  alias Keila.Automations.Recipes
  alias Keila.Integrations.Evo.Units

  @impl true
  def mount(_params, session, socket) do
    Gettext.put_locale(session["locale"])
    project = session["current_project"]

    socket =
      socket
      |> assign(:current_project, project)
      |> assign(:automations, Automations.list_automations(project.id))
      |> assign(:recipes, Recipes.list())
      |> assign(:units, Units.list_active_units(project.id))
      |> assign(:activating_recipe, nil)
      |> assign(:current_recipe, nil)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(KeilaWeb.AutomationsView, "index_live.html", assigns)
  end

  @impl true
  def handle_event("open-recipe", %{"slug" => slug}, socket) do
    case Recipes.get(slug) do
      {:ok, recipe} ->
        {:noreply, assign(socket, activating_recipe: slug, current_recipe: recipe)}

      _ ->
        {:noreply, put_flash(socket, :error, "Receita não encontrada.")}
    end
  end

  def handle_event("close-recipe", _params, socket) do
    {:noreply, assign(socket, activating_recipe: nil, current_recipe: nil)}
  end

  def handle_event("activate-recipe", params, socket) do
    project_id = socket.assigns.current_project.id
    slug = params["slug"]
    unit_id = if params["evo_unit_id"] in ["", nil], do: nil, else: params["evo_unit_id"]

    case Automations.activate_recipe(project_id, slug, unit_id) do
      {:ok, _automation} ->
        socket =
          socket
          |> assign(:automations, Automations.list_automations(project_id))
          |> assign(:activating_recipe, nil)
          |> put_flash(:info, "Automação ativada! Pode relaxar — a gente cuida do envio.")

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Não consegui ativar a receita.")}
    end
  end

  def handle_event("toggle-automation", %{"id" => id}, socket) do
    automation = Automations.get_automation(id)

    case automation && Automations.set_active(automation, !automation.active) do
      {:ok, _} ->
        {:noreply,
         assign(socket, :automations, Automations.list_automations(socket.assigns.current_project.id))}

      _ ->
        {:noreply, put_flash(socket, :error, "Não consegui alterar.")}
    end
  end

  def handle_event("delete-automation", %{"id" => id}, socket) do
    automation = Automations.get_automation(id)

    case automation && Automations.delete_automation(automation) do
      {:ok, _} ->
        socket =
          socket
          |> assign(:automations, Automations.list_automations(socket.assigns.current_project.id))
          |> put_flash(:info, "Automação removida.")

        {:noreply, socket}

      _ ->
        {:noreply, put_flash(socket, :error, "Não consegui remover.")}
    end
  end

  @doc false
  def step_summary(steps) when is_list(steps) do
    steps
    |> Enum.sort_by(& &1.order)
    |> Enum.map_join(" → ", fn s ->
      cond do
        s.delay_days == 0 -> "hoje"
        s.delay_days == 1 -> "amanhã"
        true -> "+#{s.delay_days}d"
      end
    end)
  end

  def step_summary(_), do: "—"
end
