defmodule KeilaWeb.InviteController do
  @moduledoc """
  Rota pública pra aceitar convite. URL `/invite/:token` no email.

  Fluxo:
  1. show: valida token + mostra form pra criar senha
  2. accept: cria User, adiciona ao Group do projeto, marca convite aceito,
     loga o usuário e redireciona pro projeto
  """
  use KeilaWeb, :controller

  alias Keila.Auth
  alias Keila.Auth.Invitations
  alias Keila.Projects

  def show(conn, %{"token" => token}) do
    invitation = Invitations.get_by_token(token)

    cond do
      is_nil(invitation) ->
        conn
        |> put_flash(:error, "Convite inválido ou já usado.")
        |> redirect(to: "/auth/login")

      not Invitations.valid?(invitation) ->
        conn
        |> put_flash(:error, "Esse convite expirou. Pede um novo pra quem te convidou.")
        |> redirect(to: "/auth/login")

      true ->
        conn
        |> assign(:invitation, invitation)
        |> assign(:token, token)
        |> put_view(KeilaWeb.InviteView)
        |> render("show.html")
    end
  end

  def accept(conn, %{"token" => token, "user" => %{"password" => password}}) do
    invitation = Invitations.get_by_token(token)

    cond do
      is_nil(invitation) or not Invitations.valid?(invitation) ->
        conn
        |> put_flash(:error, "Convite inválido ou expirado.")
        |> redirect(to: "/auth/login")

      String.length(to_string(password)) < 10 ->
        conn
        |> put_flash(:error, "Senha precisa ter pelo menos 10 caracteres.")
        |> redirect(to: "/invite/#{token}")

      true ->
        do_accept(conn, invitation, password)
    end
  end

  defp do_accept(conn, invitation, password) do
    case Auth.create_user(%{email: invitation.email, password: password},
           skip_activation_email: true
         ) do
      {:ok, user} ->
        # Ativa o user na hora (já confirmou email aceitando o convite)
        _ = Auth.activate_user(user.id)

        # Adiciona ao Group do projeto
        project = Projects.get_project(invitation.project_id)

        if project && project.group_id do
          _ = Auth.add_user_to_group(user.id, project.group_id)
        end

        # Marca invitation como aceito
        Invitations.accept(invitation, user)

        conn
        |> put_flash(:info, "🎉 Bem-vindo(a)! Sua conta foi criada.")
        |> KeilaWeb.AuthSession.start_auth_session(user.id)
        |> redirect(to: "/projects/#{invitation.project_id}")

      {:error, changeset} ->
        msg =
          changeset.errors
          |> Enum.map(fn {field, {m, _}} -> "#{field}: #{m}" end)
          |> Enum.join(", ")

        conn
        |> put_flash(:error, "Erro ao criar conta: #{msg}")
        |> redirect(to: "/invite/#{invitation.token}")
    end
  end
end
