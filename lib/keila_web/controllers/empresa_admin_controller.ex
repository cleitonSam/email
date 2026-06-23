defmodule KeilaWeb.EmpresaAdminController do
  use KeilaWeb, :controller
  alias Keila.Empresas
  alias Keila.Empresas.Empresa
  alias Keila.Auditoria

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
      {:ok, empresa} ->
        Auditoria.registrar_conn(conn, "empresa.cadastrada",
          entity: empresa,
          project_id: empresa.project_id,
          metadata: %{cnpj: empresa.cnpj, nome: empresa.nome}
        )

        conn
        |> put_flash(:info, dgettext("admin", "Empresa cadastrada e convite enviado."))
        |> redirect(to: Routes.empresa_admin_path(conn, :index))

      {:ok, empresa, :email_failed} ->
        Auditoria.registrar_conn(conn, "empresa.cadastrada",
          entity: empresa,
          project_id: empresa.project_id,
          metadata: %{cnpj: empresa.cnpj, nome: empresa.nome, email_failed: true}
        )

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

  @spec aprovar_kyb(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def aprovar_kyb(conn, %{"id" => id}) do
    with_empresa(conn, id, fn empresa ->
      {:ok, empresa} = Empresas.aprovar_kyb(empresa, conn.assigns.current_user.id)

      Auditoria.registrar_conn(conn, "empresa.kyb_aprovado",
        entity: empresa,
        project_id: empresa.project_id
      )

      conn
      |> put_flash(:info, dgettext("admin", "KYB aprovado. Empresa liberada para enviar."))
      |> redirect(to: Routes.empresa_admin_path(conn, :index))
    end)
  end

  @spec rejeitar_kyb(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def rejeitar_kyb(conn, %{"id" => id} = params) do
    motivo = params["motivo"] || ""

    with_empresa(conn, id, fn empresa ->
      {:ok, empresa} = Empresas.rejeitar_kyb(empresa, conn.assigns.current_user.id, motivo)

      Auditoria.registrar_conn(conn, "empresa.kyb_rejeitado",
        entity: empresa,
        project_id: empresa.project_id,
        metadata: %{motivo: motivo}
      )

      conn
      |> put_flash(:info, dgettext("admin", "KYB rejeitado. Envio permanece bloqueado."))
      |> redirect(to: Routes.empresa_admin_path(conn, :index))
    end)
  end

  @spec bloquear(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def bloquear(conn, %{"id" => id}) do
    with_empresa(conn, id, fn empresa ->
      {:ok, empresa} = Empresas.bloquear(empresa)

      Auditoria.registrar_conn(conn, "empresa.bloqueada",
        entity: empresa,
        project_id: empresa.project_id
      )

      conn
      |> put_flash(:info, dgettext("admin", "Empresa bloqueada. Disparos suspensos."))
      |> redirect(to: Routes.empresa_admin_path(conn, :index))
    end)
  end

  @spec desbloquear(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def desbloquear(conn, %{"id" => id}) do
    with_empresa(conn, id, fn empresa ->
      {:ok, empresa} = Empresas.desbloquear(empresa)

      Auditoria.registrar_conn(conn, "empresa.desbloqueada",
        entity: empresa,
        project_id: empresa.project_id
      )

      conn
      |> put_flash(:info, dgettext("admin", "Empresa reativada."))
      |> redirect(to: Routes.empresa_admin_path(conn, :index))
    end)
  end

  defp with_empresa(conn, id, fun) do
    case Empresas.get_empresa(id) do
      nil -> conn |> put_status(404) |> halt()
      empresa -> fun.(empresa)
    end
  end

  defp authorize(conn, _) do
    case conn.assigns.is_admin? do
      true -> conn
      false -> conn |> put_status(404) |> halt()
    end
  end
end
