defmodule KeilaWeb.EvoLive do
  use KeilaWeb, :live_view
  alias Keila.Contacts
  alias Keila.Projects
  alias Keila.Integrations.Evo

  @impl true
  def mount(_params, session, socket) do
    Gettext.put_locale(session["locale"])
    project = session["current_project"]

    # Reload project to get data field
    project = Projects.get_project(project.id)

    today = Date.utc_today()
    first_day = %{today | day: 1}
    last_day = Date.end_of_month(today)

    evo_dns = get_evo_config(project, "evo_dns")
    evo_secret = get_evo_config(project, "evo_secret_key")

    socket =
      socket
      |> assign(:current_project, project)
      |> assign(:prospects, [])
      |> assign(:selected, MapSet.new())
      |> assign(:loading, false)
      |> assign(:error, nil)
      |> assign(:total_fetched, 0)
      |> assign(:total_with_email, 0)
      |> assign(:imported_count, 0)
      |> assign(:importing, false)
      |> assign(:import_done, false)
      |> assign(:date_start, Date.to_iso8601(first_day))
      |> assign(:date_end, Date.to_iso8601(last_day))
      |> assign(:search, "")
      |> assign(:evo_dns, evo_dns || "")
      |> assign(:evo_secret, evo_secret || "")
      |> assign(:config_ok, evo_dns != nil and evo_secret != nil)
      |> assign(:show_settings, evo_dns == nil or evo_secret == nil)
      |> assign(:settings_saved, false)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(KeilaWeb.EvoView, "evo_live.html", assigns)
  end

  @impl true
  def handle_event("save-settings", %{"evo_dns" => dns, "evo_secret_key" => secret}, socket) do
    project = socket.assigns.current_project

    case Projects.update_project_data(project.id, %{
           "evo_dns" => String.trim(dns),
           "evo_secret_key" => String.trim(secret)
         }) do
      {:ok, updated_project} ->
        socket =
          socket
          |> assign(:current_project, updated_project)
          |> assign(:evo_dns, String.trim(dns))
          |> assign(:evo_secret, String.trim(secret))
          |> assign(:config_ok, String.trim(dns) != "" and String.trim(secret) != "")
          |> assign(:settings_saved, true)
          |> assign(:show_settings, false)

        {:noreply, socket}

      {:error, _} ->
        {:noreply, assign(socket, :error, "Failed to save settings")}
    end
  end

  def handle_event("toggle-settings", _params, socket) do
    {:noreply, assign(socket, :show_settings, !socket.assigns.show_settings)}
  end

  def handle_event("fetch-prospects", %{"date_start" => date_start, "date_end" => date_end}, socket) do
    socket =
      socket
      |> assign(:loading, true)
      |> assign(:error, nil)
      |> assign(:prospects, [])
      |> assign(:selected, MapSet.new())
      |> assign(:import_done, false)
      |> assign(:imported_count, 0)
      |> assign(:date_start, date_start)
      |> assign(:date_end, date_end)
      |> assign(:settings_saved, false)

    send(self(), :do_fetch)
    {:noreply, socket}
  end

  def handle_event("toggle-select", %{"email" => email}, socket) do
    selected = socket.assigns.selected

    selected =
      if MapSet.member?(selected, email) do
        MapSet.delete(selected, email)
      else
        MapSet.put(selected, email)
      end

    {:noreply, assign(socket, :selected, selected)}
  end

  def handle_event("select-all", _params, socket) do
    all_emails =
      socket.assigns.prospects
      |> filter_by_search(socket.assigns.search)
      |> Enum.map(& &1.email)
      |> MapSet.new()

    {:noreply, assign(socket, :selected, all_emails)}
  end

  def handle_event("deselect-all", _params, socket) do
    {:noreply, assign(socket, :selected, MapSet.new())}
  end

  def handle_event("search", %{"search" => search}, socket) do
    {:noreply, assign(socket, :search, search)}
  end

  def handle_event("import-contacts", _params, socket) do
    socket = assign(socket, :importing, true)
    send(self(), :do_import)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:do_fetch, socket) do
    project = socket.assigns.current_project

    opts = [
      register_date_start: socket.assigns.date_start,
      register_date_end: socket.assigns.date_end,
      evo_dns: get_evo_config(project, "evo_dns"),
      evo_secret_key: get_evo_config(project, "evo_secret_key")
    ]

    socket =
      case Evo.fetch_prospects(opts) do
        {:ok, prospects, total} ->
          socket
          |> assign(:prospects, prospects)
          |> assign(:total_fetched, total)
          |> assign(:total_with_email, length(prospects))
          |> assign(:loading, false)

        {:error, reason} ->
          socket
          |> assign(:error, reason)
          |> assign(:loading, false)
      end

    {:noreply, socket}
  end

  def handle_info(:do_import, socket) do
    project_id = socket.assigns.current_project.id
    selected = socket.assigns.selected
    prospects = socket.assigns.prospects

    to_import = Enum.filter(prospects, fn p -> MapSet.member?(selected, p.email) end)

    # Import contacts
    imported =
      Enum.reduce(to_import, 0, fn prospect, count ->
        params = %{
          "email" => prospect.email,
          "first_name" => prospect.first_name,
          "last_name" => prospect.last_name,
          "data" => %{
            "phone" => prospect.phone,
            "evo_source" => prospect.source,
            "evo_status" => prospect.status,
            "evo_branch" => prospect.branch,
            "evo_id" => prospect.id_evo,
            "evo_register_date" => prospect.register_date,
            "evo_type" => "prospect"
          }
        }

        case upsert_contact(project_id, params) do
          {:ok, _contact} -> count + 1
          _ -> count
        end
      end)

    # Create or update segment "Prospects EVO"
    ensure_evo_segment(project_id)

    socket =
      socket
      |> assign(:importing, false)
      |> assign(:import_done, true)
      |> assign(:imported_count, imported)

    {:noreply, socket}
  end

  defp upsert_contact(project_id, params) do
    case Contacts.get_project_contact_by_email(project_id, params["email"]) do
      nil ->
        Contacts.create_contact(project_id, params)

      contact ->
        # Merge data to avoid losing existing fields
        new_data = Map.merge(contact.data || %{}, params["data"])
        updated_params = Map.put(params, "data", new_data)
        Contacts.update_contact(contact.id, updated_params)
    end
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp ensure_evo_segment(project_id) do
    segments = Contacts.get_project_segments(project_id)

    unless Enum.any?(segments, fn s -> s.name == "Prospects EVO" end) do
      Contacts.create_segment(project_id, %{
        "name" => "Prospects EVO",
        "filter" => %{
          "$and" => [
            %{"data.evo_id" => %{"$ne" => nil}}
          ]
        }
      })
    end
  end

  defp filter_by_search(prospects, ""), do: prospects

  defp filter_by_search(prospects, search) do
    search = String.downcase(search)

    Enum.filter(prospects, fn p ->
      String.contains?(String.downcase(p.name), search) or
        String.contains?(String.downcase(p.email), search) or
        String.contains?(String.downcase(p.phone || ""), search)
    end)
  end

  defp get_evo_config(project, key) do
    case (project.data || %{}) |> Map.get(key) do
      nil -> nil
      "" -> nil
      val -> val
    end
  end
end
