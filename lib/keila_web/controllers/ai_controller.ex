defmodule KeilaWeb.AIController do
  @moduledoc """
  Endpoints JSON pra editar/criar emails MJML via IA.
  """
  use KeilaWeb, :controller

  alias Keila.AI.EmailEditor
  alias Keila.Mailings
  alias Keila.Projects.Brand
  alias Keila.Integrations.OpenRouter

  def status(conn, _params) do
    json(conn, %{configured: OpenRouter.configured?()})
  end

  def edit_mjml(conn, %{"mjml" => mjml, "instruction" => instruction}) do
    if not OpenRouter.configured?() do
      conn |> put_status(503) |> json(%{error: "IA não configurada. Configure OPENROUTER_API_KEY no servidor."})
    else
      brand = current_brand(conn)
      case EmailEditor.edit(mjml, instruction, brand) do
        {:ok, new_mjml} -> json(conn, %{mjml: new_mjml})
        {:error, reason} -> conn |> put_status(422) |> json(%{error: "#{inspect(reason)}"})
      end
    end
  end

  def edit_mjml(conn, _) do
    conn |> put_status(400) |> json(%{error: "Faltam parâmetros mjml e instruction"})
  end

  def create_mjml(conn, %{"description" => description}) do
    project = current_project(conn)

    if not OpenRouter.configured?() do
      conn |> put_status(503) |> json(%{error: "IA não configurada."})
    else
      brand = current_brand(conn)

      case EmailEditor.create(description, brand) do
        {:ok, mjml} ->
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
              json(conn, %{mjml: mjml})
          end

        {:error, reason} ->
          conn |> put_status(422) |> json(%{error: "#{inspect(reason)}"})
      end
    end
  end

  def create_mjml(conn, _) do
    conn |> put_status(400) |> json(%{error: "Falta parâmetro description"})
  end

  defp current_project(conn), do: conn.assigns.current_project

  defp current_brand(conn) do
    case conn.assigns[:current_project] do
      nil -> nil
      project -> Brand.get(project)
    end
  end
end
