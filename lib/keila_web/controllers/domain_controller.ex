defmodule KeilaWeb.DomainController do
  @moduledoc """
  Gestão de domínios de envio de um projeto/empresa e verificação de DNS
  (regra inegociável nº 1 do Prompt Mestre).
  """
  use KeilaWeb, :controller

  alias Keila.Deliverability
  alias Keila.Deliverability.EmailDomain
  alias Keila.Auditoria

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    conn
    |> put_meta(:title, gettext("Domínios de envio"))
    |> assign(:domains, Deliverability.list_por_projeto(project_id(conn)))
    |> assign(:changeset, EmailDomain.creation_changeset(%{}))
    |> render("index.html")
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"email_domain" => params}) do
    case Deliverability.criar(project_id(conn), params) do
      {:ok, domain} ->
        # Verifica logo após cadastrar para já mostrar o status real.
        {:ok, domain} = Deliverability.verificar_dominio(domain)

        Auditoria.registrar_conn(conn, "dominio.cadastrado",
          entity: domain,
          project_id: project_id(conn),
          metadata: %{domain: domain.domain, status: domain.status}
        )

        conn
        |> put_flash(:info, gettext("Domínio cadastrado e verificado."))
        |> redirect(to: Routes.domain_path(conn, :index, project_id(conn)))

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> assign(:domains, Deliverability.list_por_projeto(project_id(conn)))
        |> assign(:changeset, changeset)
        |> render("index.html")
    end
  end

  @spec verify(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def verify(conn, %{"id" => id}) do
    with_domain(conn, id, fn domain ->
      {:ok, domain} = Deliverability.verificar_dominio(domain)

      Auditoria.registrar_conn(conn, "dominio.verificado",
        entity: domain,
        project_id: project_id(conn),
        metadata: %{domain: domain.domain, status: domain.status}
      )

      flash =
        if domain.status == "verified",
          do: {:info, gettext("Domínio verificado com sucesso.")},
          else: {:error, domain.last_error || gettext("Falha na verificação de DNS.")}

      conn
      |> put_flash(elem(flash, 0), elem(flash, 1))
      |> redirect(to: Routes.domain_path(conn, :index, project_id(conn)))
    end)
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    with_domain(conn, id, fn domain ->
      Deliverability.excluir(domain)

      Auditoria.registrar_conn(conn, "dominio.removido",
        project_id: project_id(conn),
        metadata: %{domain: domain.domain}
      )

      conn
      |> put_flash(:info, gettext("Domínio removido."))
      |> redirect(to: Routes.domain_path(conn, :index, project_id(conn)))
    end)
  end

  defp with_domain(conn, id, fun) do
    case Deliverability.get_por_projeto(project_id(conn), id) do
      nil -> conn |> put_status(404) |> halt()
      domain -> fun.(domain)
    end
  end

  defp project_id(conn), do: conn.assigns.current_project.id
end
