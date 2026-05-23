defmodule KeilaWeb.NpsController do
  @moduledoc """
  Painel de NPS de um projeto: cria e gerencia pesquisas, dispara os envios
  por e-mail e mostra o dashboard de resultados.

  Tudo é escopado pelo projeto atual (`conn.assigns.current_project`) —
  o plug `:authorize` recusa qualquer pesquisa que não seja do projeto.
  """
  use KeilaWeb, :controller

  alias Keila.Nps
  alias Keila.Nps.Pesquisa
  alias Keila.Contacts

  plug :authorize when action in [:edit, :update, :delete, :enviar, :post_enviar, :resultados, :export]

  # ── Pesquisas ──────────────────────────────────────────────────────────

  def index(conn, _params) do
    project = current_project(conn)
    pesquisas = Nps.list_pesquisas(project.id)

    stats =
      Map.new(pesquisas, fn p -> {p.id, Nps.estatisticas(p.id)} end)

    conn
    |> assign(:pesquisas, pesquisas)
    |> assign(:stats, stats)
    |> put_meta(:title, "NPS")
    |> render("index.html")
  end

  def new(conn, _params) do
    conn
    |> assign(:changeset, Nps.change_pesquisa(%Pesquisa{}))
    |> assign(:pergunta_padrao, Pesquisa.pergunta_padrao())
    |> put_meta(:title, "Nova pesquisa de NPS")
    |> render("new.html")
  end

  def create(conn, %{"pesquisa" => params}) do
    project = current_project(conn)

    case Nps.create_pesquisa(project.id, params) do
      {:ok, pesquisa} ->
        conn
        |> put_flash(:info, "Pesquisa criada! Agora é só enviar pros seus contatos.")
        |> redirect(to: Routes.nps_path(conn, :enviar, project.id, pesquisa.id))

      {:error, changeset} ->
        conn
        |> assign(:changeset, %{changeset | action: :insert})
        |> assign(:pergunta_padrao, Pesquisa.pergunta_padrao())
        |> render("new.html")
    end
  end

  def edit(conn, _params) do
    conn
    |> assign(:changeset, Nps.change_pesquisa(conn.assigns.pesquisa))
    |> assign(:pergunta_padrao, Pesquisa.pergunta_padrao())
    |> put_meta(:title, "Editar pesquisa")
    |> render("edit.html")
  end

  def update(conn, %{"pesquisa" => params}) do
    project = current_project(conn)

    case Nps.update_pesquisa(conn.assigns.pesquisa, params) do
      {:ok, _pesquisa} ->
        conn
        |> put_flash(:info, "Pesquisa atualizada.")
        |> redirect(to: Routes.nps_path(conn, :index, project.id))

      {:error, changeset} ->
        conn
        |> assign(:changeset, %{changeset | action: :update})
        |> assign(:pergunta_padrao, Pesquisa.pergunta_padrao())
        |> render("edit.html")
    end
  end

  def delete(conn, _params) do
    project = current_project(conn)
    {:ok, _} = Nps.delete_pesquisa(conn.assigns.pesquisa)

    conn
    |> put_flash(:info, "Pesquisa removida.")
    |> redirect(to: Routes.nps_path(conn, :index, project.id))
  end

  # ── Envio por e-mail ───────────────────────────────────────────────────

  def enviar(conn, _params) do
    project = current_project(conn)
    pesquisa = conn.assigns.pesquisa

    contatos =
      Contacts.get_project_contacts(project.id)
      |> Enum.filter(&(&1.status == :active))

    senders = Keila.Mailings.get_project_senders(project.id)

    conn
    |> assign(:contatos, contatos)
    |> assign(:senders, senders)
    |> assign(:stats, Nps.estatisticas(pesquisa.id))
    |> put_meta(:title, "Enviar pesquisa")
    |> render("enviar.html")
  end

  def post_enviar(conn, params) do
    project = current_project(conn)
    pesquisa = conn.assigns.pesquisa
    contato_ids = Map.get(params, "contato_ids", []) |> List.wrap()
    sender_id = Map.get(params, "sender_id")
    sender = sender_id && Keila.Mailings.get_project_sender(project.id, sender_id)

    cond do
      contato_ids == [] ->
        conn
        |> put_flash(:error, "Selecione pelo menos um contato.")
        |> redirect(to: Routes.nps_path(conn, :enviar, project.id, pesquisa.id))

      is_nil(sender) ->
        conn
        |> put_flash(:error, "Escolha um remetente. Configure um em Remetentes se ainda não tiver.")
        |> redirect(to: Routes.nps_path(conn, :enviar, project.id, pesquisa.id))

      true ->
        {:ok, envios} = Nps.criar_envios(pesquisa, contato_ids)
        disparar(envios, pesquisa, project, sender)

        conn
        |> put_flash(
          :info,
          "Disparando a pesquisa para #{length(envios)} contato(s). As respostas aparecem no painel de resultados."
        )
        |> redirect(to: Routes.nps_path(conn, :resultados, project.id, pesquisa.id))
    end
  end

  defp disparar([], _pesquisa, _project, _sender), do: :ok

  defp disparar(envios, pesquisa, project, sender) do
    nome_empresa = empresa_nome(project)

    Task.start(fn ->
      Enum.each(envios, fn envio ->
        contato = Keila.Contacts.get_contact(envio.contato_id)

        if contato && contato.email do
          nome = String.trim("#{contato.first_name} #{contato.last_name}")

          email =
            Keila.Nps.Email.build(pesquisa, envio,
              to_email: contato.email,
              to_name: if(nome == "", do: nil, else: nome),
              nome_empresa: nome_empresa
            )

          case Keila.Mailer.deliver_with_sender(email, sender) do
            {:ok, _} -> Nps.marcar_enviado(envio)
            {:error, _} -> Nps.marcar_bounce(envio)
          end
        else
          Nps.marcar_bounce(envio)
        end
      end)
    end)

    :ok
  end

  # ── Resultados ─────────────────────────────────────────────────────────

  def resultados(conn, _params) do
    pesquisa = conn.assigns.pesquisa
    project = current_project(conn)

    conn
    |> assign(:stats, Nps.estatisticas(pesquisa.id))
    |> assign(:respostas, Nps.list_respostas(pesquisa.id))
    |> assign(:project_id, project.id)
    |> put_meta(:title, "Resultados — #{pesquisa.nome}")
    |> render("resultados.html")
  end

  def export(conn, _params) do
    pesquisa = conn.assigns.pesquisa
    respostas = Nps.list_respostas(pesquisa.id)

    linhas =
      Enum.map(respostas, fn r ->
        contato = r.envio && r.envio.contato
        nome = if contato, do: String.trim("#{contato.first_name} #{contato.last_name}"), else: ""
        email = (contato && contato.email) || ""
        data = if r.respondido_em, do: Calendar.strftime(r.respondido_em, "%d/%m/%Y %H:%M"), else: ""
        comentario = (r.comentario || "") |> String.replace("\"", "\"\"")

        ~s("#{nome}","#{email}",#{r.nota},"#{categoria_label(r.categoria)}","#{data}","#{comentario}")
      end)

    csv = ["Nome,E-mail,Nota,Categoria,Respondido em,Comentário" | linhas] |> Enum.join("\r\n")

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header(
      "content-disposition",
      ~s(attachment; filename="nps_#{pesquisa.id}.csv")
    )
    |> send_resp(200, "﻿" <> csv)
  end

  # ── Helpers ────────────────────────────────────────────────────────────

  defp categoria_label("promotor"), do: "Promotor"
  defp categoria_label("neutro"), do: "Neutro"
  defp categoria_label("detrator"), do: "Detrator"
  defp categoria_label(other), do: other

  defp empresa_nome(project) do
    case Keila.Empresas.get_empresa_por_projeto(project.id) do
      %{nome: nome} when is_binary(nome) and nome != "" -> nome
      _ -> project.name
    end
  end

  defp current_project(conn), do: conn.assigns.current_project

  defp authorize(conn, _) do
    project_id = current_project(conn).id
    pesquisa_id = conn.path_params["id"]

    case Nps.get_project_pesquisa(project_id, pesquisa_id) do
      nil ->
        conn
        |> put_status(404)
        |> halt()

      pesquisa ->
        assign(conn, :pesquisa, pesquisa)
    end
  end
end
