defmodule KeilaWeb.WizardController do
  use KeilaWeb, :controller
  import Phoenix.LiveView.Controller

  alias Keila.Media
  alias Keila.Projects.Brand

  def show(conn, _params) do
    live_render(conn, KeilaWeb.WizardLive,
      session: %{
        "current_project" => current_project(conn),
        "current_user" => conn.assigns[:current_user],
        "locale" => Gettext.get_locale()
      }
    )
  end

  @doc """
  Upload do logo via POST tradicional (form HTML multipart).

  Substitui o LiveView upload que tava bugado. Recebe Plug.Upload,
  sobe pro ImageKit e redireciona de volta pro wizard (que detecta
  o logo_url salvo e avança pra step 3).
  """
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
        |> put_flash(:info, "✓ Logo enviado! Extraindo cores...")
        |> redirect(to: "/projects/#{project.id}/setup")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Erro no upload: #{inspect(reason)}")
        |> redirect(to: "/projects/#{project.id}/setup")
    end
  end

  def upload_logo(conn, _params) do
    project = current_project(conn)

    conn
    |> put_flash(:error, "Selecione um arquivo de logo.")
    |> redirect(to: "/projects/#{project.id}/setup")
  end

  defp current_project(conn), do: conn.assigns.current_project
end
