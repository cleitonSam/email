defmodule KeilaWeb.AIController do
  @moduledoc """
  Endpoints JSON pra editar/criar emails MJML via IA.

  Chamados via fetch() pelos modais "🪄 Ajustar com IA" no editor de campanha
  e "✨ Criar com IA" na galeria de modelos.
  """
  use KeilaWeb, :controller

  alias Keila.AI.EmailEditor
  alias Keila.Mailings
  alias Keila.Integrations.OpenRouter

  def status(conn, _params) do
    json(conn, %{configured: OpenRouter.configured?()})
  end

  def edit_mjml(conn, %{"mjml" => mjml, "instruction" => instruction}) do
    if not OpenRouter.configured?() do
      conn
      |> put_status(503)
      |> json(%{error: "IA não configurada. Configure OPENROUTER_API_KEY no servidor."})
    else
      case EmailEditor.edit(mjml, instruction) do
        {:ok, new_mjml} ->
          json(conn, %{mjml: new_mjml})

        {:error, reason} ->
          conn
          |> put_status(422)
          |> json(%{error: "#{inspect(reason)}"})
      end
    end
  end

  def edit_mjml(conn, _) do
    conn |> put_status(400) |> json(%{error: "Faltam parâmetros mjml e instruction"})
  end

  def create_mjml(conn, %{"description" => description}) do
    project = current_project(conn)

    if not OpenRouter.configured?() do
      conn
      |> put_status(503)
      |> json(%{error: "IA não configurada."})
    else
      case EmailEditor.create(description) do
        {:ok, mjml} ->
          # Cria uma campanha em rascunho com o MJML gerado pela IA
          params = %{
            "subject" => "Email criado com IA — edite o assunto",
            "mjml_body" => mjml,
            "settings" => %{"type" => "mjml"},
            "data" => %{"created_by_ai" => true}
          }

          case Mailings.create_campaign(project.id, params) do
            {:ok, campaign} ->
              json(conn, %{
                mjml: mjml,
                campaign_id: campaign.id,
                redirect_url: "/projects/#{project.id}/campaigns/#{campaign.id}"
              })

            {:error, _changeset} ->
              # Mesmo se não conseguiu criar campanha, devolve o MJML
              json(conn, %{mjml: mjml})
          end

        {:error, reason} ->
          conn
          |> put_status(422)
          |> json(%{error: "#{inspect(reason)}"})
      end
    end
  end

  def create_mjml(conn, _) do
    conn |> put_status(400) |> json(%{error: "Falta parâmetro description"})
  end

  defp current_project(conn), do: conn.assigns.current_project
end
