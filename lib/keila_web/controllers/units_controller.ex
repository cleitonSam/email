defmodule KeilaWeb.UnitsController do
  use KeilaWeb, :controller
  import Phoenix.LiveView.Controller

  def index(conn, _params) do
    live_render(conn, KeilaWeb.UnitsLive,
      session: %{
        "current_project" => current_project(conn),
        "locale" => Gettext.get_locale()
      }
    )
  end

  defp current_project(conn), do: conn.assigns.current_project
end
