defmodule KeilaWeb.TeamController do
  @moduledoc "Tela 'Equipe' do projeto."
  use KeilaWeb, :controller

  alias Keila.Auth.Invitations

  def index(conn, _params) do
    project = current_project(conn)
    invitations = Invitations.list_pending(project.id)
    members = Invitations.list_accepted(project.id)

    conn
    |> assign(:invitations, invitations)
    |> assign(:members, members)
    |> assign(:flash_email, "")
    |> render("index.html")
  end

  def invite(conn, %{"invitation" => %{"email" => email}}) do
    project = current_project(conn)
    user = conn.assigns[:current_user]
    email = email |> to_string() |> String.trim() |> String.downcase()

    cond do
      email == "" ->
        conn |> put_flash(:error, "Informe o email da pessoa.") |> redirect(to: "/projects/#{project.id}/team")

      not String.contains?(email, "@") ->
        conn |> put_flash(:error, "Email inválido.") |> redirect(to: "/projects/#{project.id}/team")

      true ->
        params = %{email: email, project_id: project.id, invited_by_user_id: user && user.id, role: "member"}

        case Invitations.create(params) do
          {:ok, _invitation} ->
            conn |> put_flash(:info, "✓ Convite enviado pra #{email}") |> redirect(to: "/projects/#{project.id}/team")

          {:ok, invitation, :email_failed} ->
            link = "/invite/#{invitation.token}"
            conn |> put_flash(:error, "Convite criado mas falhou ao enviar email. Compartilhe este link manualmente: #{link}") |> redirect(to: "/projects/#{project.id}/team")

          {:error, _changeset} ->
            conn |> put_flash(:error, "Erro ao criar convite. Talvez essa pessoa já tenha sido convidada.") |> redirect(to: "/projects/#{project.id}/team")
        end
    end
  end

  def revoke(conn, %{"id" => id}) do
    project = current_project(conn)
    invitation = Invitations.get(id)
    if invitation && invitation.project_id == project.id, do: Invitations.revoke(invitation)
    conn |> put_flash(:info, "Convite cancelado.") |> redirect(to: "/projects/#{project.id}/team")
  end

  @doc "Remove um membro do projeto (deleta o invitation aceito)."
  def remove_member(conn, %{"id" => id}) do
    project = current_project(conn)
    invitation = Invitations.get(id)

    if invitation && invitation.project_id == project.id do
      Invitations.revoke(invitation)
      conn |> put_flash(:info, "Membro removido do projeto.") |> redirect(to: "/projects/#{project.id}/team")
    else
      conn |> put_flash(:error, "Membro não encontrado.") |> redirect(to: "/projects/#{project.id}/team")
    end
  end

  defp current_project(conn), do: conn.assigns.current_project
end
