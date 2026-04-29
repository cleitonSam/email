defmodule KeilaWeb.MediaController do
  use KeilaWeb, :controller
  import Phoenix.LiveView.Controller

  def index(conn, _params) do
    live_render(conn, KeilaWeb.MediaLive,
      session: %{
        "current_project" => current_project(conn),
        "current_user" => conn.assigns[:current_user],
        "locale" => Gettext.get_locale()
      }
    )
  end

  defp current_project(conn), do: conn.assigns.current_project
end
