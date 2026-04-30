defmodule KeilaWeb.SegmentIndexLive do
  use KeilaWeb, :live_view
  require Logger

  alias Keila.Contacts
  alias Keila.Mailings

  @impl true
  def mount(_params, session, socket) do
    project_id = session["current_project"].id
    segments = Contacts.get_project_segments(project_id)
    campaigns = Mailings.get_project_campaigns(project_id)
    
    # Map segment_id -> list of campaigns
    campaigns_map = Enum.group_by(campaigns, & &1.segment_id)

    {:ok,
     socket
     |> assign(:current_project, session["current_project"])
     |> assign(:segments, segments)
     |> assign(:campaigns_map, campaigns_map)
     |> assign(:preview_html, nil)
     |> assign(:preview_campaign_id, nil)}
  end

  @impl true
  def handle_event("preview-email", %{"id" => campaign_id}, socket) do
    campaign = Mailings.get_campaign(campaign_id)

    preview_html =
      cond do
        campaign && campaign.html_body && campaign.html_body != "" ->
          campaign.html_body

        campaign && campaign.mjml_body && campaign.mjml_body != "" ->
          case Mjml.to_html(campaign.mjml_body) do
            {:ok, html} -> html
            _ -> "<p style='padding:40px;color:#999;text-align:center'>Não foi possível compilar o preview.</p>"
          end

        true ->
          "<p style='padding:40px;color:#999;text-align:center'>Este email ainda não tem conteúdo.</p>"
      end

    {:noreply,
     socket
     |> assign(:preview_campaign_id, campaign_id)
     |> assign(:preview_html, preview_html)}
  end

  @impl true
  def handle_event("close-preview", _params, socket) do
    {:noreply,
     socket
     |> assign(:preview_campaign_id, nil)
     |> assign(:preview_html, nil)}
  end

  @impl true
  def render(assigns) do
    KeilaWeb.SegmentView.render("index_live.html", assigns)
  end
end
