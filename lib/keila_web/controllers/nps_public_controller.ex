defmodule KeilaWeb.NpsPublicController do
  @moduledoc """
  Página pública de resposta de NPS: `/nps/:token`.

  Não exige login — o token do envio é a credencial. Cada token responde
  uma única vez. A página é renderizada com um layout próprio (`nps.html`),
  isolado do painel administrativo.
  """
  use KeilaWeb, :controller

  alias Keila.Nps

  plug :put_root_layout, false
  plug :put_layout, {KeilaWeb.LayoutView, :nps}

  def show(conn, %{"token" => token}) do
    case Nps.get_envio_by_token(token) do
      nil ->
        render_invalido(conn)

      %{resposta: %Keila.Nps.Resposta{}} ->
        render_obrigado(conn, ja: true)

      envio ->
        conn
        |> assign(:page_title, "Pesquisa de satisfação")
        |> assign(:token, token)
        |> assign(:pesquisa, envio.pesquisa)
        |> assign(:erro, nil)
        |> render("show.html")
    end
  end

  def submit(conn, %{"token" => token} = params) do
    case Nps.get_envio_by_token(token) do
      nil ->
        render_invalido(conn)

      %{resposta: %Keila.Nps.Resposta{}} ->
        render_obrigado(conn, ja: true)

      envio ->
        attrs = %{
          "nota" => params["nota"],
          "comentario" => params["comentario"]
        }

        case Nps.registrar_resposta(envio, attrs) do
          {:ok, _resposta} ->
            render_obrigado(conn, ja: false)

          {:error, :ja_respondido} ->
            render_obrigado(conn, ja: true)

          {:error, _changeset} ->
            conn
            |> assign(:page_title, "Pesquisa de satisfação")
            |> assign(:token, token)
            |> assign(:pesquisa, envio.pesquisa)
            |> assign(:erro, "Escolha uma nota de 0 a 10 para enviar sua resposta.")
            |> render("show.html")
        end
    end
  end

  defp render_obrigado(conn, opts) do
    conn
    |> assign(:page_title, "Obrigado!")
    |> assign(:ja, Keyword.get(opts, :ja, false))
    |> render("obrigado.html")
  end

  defp render_invalido(conn) do
    conn
    |> put_status(404)
    |> assign(:page_title, "Pesquisa não encontrada")
    |> render("invalido.html")
  end
end
