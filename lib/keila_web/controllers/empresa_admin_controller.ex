defmodule KeilaWeb.EmpresaAdminController do
  use KeilaWeb, :controller
  alias Keila.Empresas
  alias Keila.Empresas.Empresa

  plug :authorize

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    conn
    |> put_meta(:title, dgettext("admin", "Empresas"))
    |> assign(:empresas, Empresas.list_empresas())
    |> render("index.html")
  end

  @spec new(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def new(conn, _params) do
    conn
    |> put_meta(:title, dgettext("admin", "Cadastrar empresa"))
    |> assign(:changeset, Empresa.creation_changeset(%{}))
    |> render("new.html")
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"empresa" => empresa_params}) do
    admin_user_id = conn.assigns.current_user.id

    case Empresas.cadastrar_empresa(admin_user_id, empresa_params) do
      {:ok, _empresa} ->
        conn
        |> put_flash(:info, dgettext("admin", "Empresa cadastrada e convite enviado."))
        |> redirect(to: Routes.empresa_admin_path(conn, :index))

      {:ok, _empresa, :email_failed} ->
        conn
        |> put_flash(
          :error,
          dgettext("admin", "Empresa cadastrada, mas o e-mail falhou. Use 'Reenviar convite'.")
        )
        |> redirect(to: Routes.empresa_admin_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> put_flash(:error, dgettext("admin", "Não foi possível cadastrar a empresa."))
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  @spec resend(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def resend(conn, %{"id" => id}) do
    case Empresas.get_empresa(id) do
      nil ->
        conn |> put_status(404) |> halt()

      empresa ->
        Empresas.reenviar_convite(empresa, conn.assigns.current_user.id)

        conn
        |> put_flash(
          :info,
          dgettext("admin", "Convite reenviado para %{email}.", email: empresa.email_responsavel)
        )
        |> redirect(to: Routes.empresa_admin_path(conn, :index))
    end
  end

  defp authorize(conn, _) do
    case conn.assigns.is_admin? do
      true -> conn
      false -> conn |> put_status(404) |> halt()
    end
  end
end
