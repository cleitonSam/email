defmodule KeilaWeb.CampaignController do
  use KeilaWeb, :controller
  alias Keila.{Contacts, Mailings, Templates}
  alias Keila.Templates.Library
  import Ecto.Changeset
  import Phoenix.LiveView.Controller

  plug :authorize when action not in [:index, :new, :post_new, :library, :from_template, :delete]

  @default_text_body File.read!("priv/email_templates/default-text-content.txt")
  @default_markdown_body File.read!("priv/email_templates/default-markdown-content.md")
  @default_mjml_body File.read!("priv/email_templates/default-mjml-content.mjml")

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    campaigns = Mailings.get_project_campaigns(current_project(conn).id)

    conn
    |> assign(:campaigns, campaigns)
    |> put_meta(:title, gettext("Campaigns"))
    |> render("index.html")
  end

  @spec new(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def new(conn, _params) do
    current_project = current_project(conn)

    conn
    |> render_new(new_campaign_changeset(current_project))
  end

  @default_settings %Mailings.Campaign.Settings{type: :block}
  @inherited_settings_fields [:type, :enable_wysiwyg, :do_not_track]
  @inherited_campaign_fields [:template_id, :segment_id, :sender_id, :public_link_enabled]
  defp new_campaign_changeset(project) do
    previous_campaign = Mailings.get_latest_project_campaign(project.id)
    previous_settings = get_in(previous_campaign, [Access.key(:settings)])

    settings_changeset =
      %Mailings.Campaign.Settings{}
      |> change((previous_settings || @default_settings) |> Map.take(@inherited_settings_fields))

    inherited_attrs =
      Map.take(previous_campaign || %{}, @inherited_campaign_fields)

    %Mailings.Campaign{}
    |> change(inherited_attrs)
    |> change(%{settings: settings_changeset})
  end

  @spec post_new(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def post_new(conn, params) do
    project = current_project(conn)

    params =
      (params["campaign"] || %{})
      |> put_default_body()

    case Mailings.create_campaign(project.id, params) do
      {:ok, campaign} ->
        redirect(conn, to: Routes.campaign_path(conn, :edit, project.id, campaign.id))

      {:error, changeset} ->
        render_new(conn, 400, changeset)
    end
  end

  defp render_new(conn, status \\ 200, changeset) do
    project = current_project(conn)

    senders = Mailings.get_project_senders(project.id)
    templates = Templates.get_project_templates(project.id)
    segments = Contacts.get_project_segments(project.id)

    conn
    |> put_status(status)
    |> put_meta(:title, gettext("New Campaign"))
    |> assign(:changeset, changeset)
    |> assign(:senders, senders)
    |> assign(:templates, templates)
    |> assign(:segments, segments)
    |> render("new.html")
  end

  defp put_default_body(params) do
    # TODO Maybe this would be better implemented as a Context module function
    case get_in(params, ["settings", "type"]) do
      "markdown" -> Map.put(params, "text_body", @default_markdown_body)
      "mjml" -> Map.put(params, "mjml_body", @default_mjml_body)
      _ -> Map.put(params, "text_body", @default_text_body)
    end
  end

  @doc """
  Galeria visual de modelos prontos.

  Lista os 8 modelos da `Keila.Templates.Library` em cards com preview iframe.
  Cada card tem botão "Usar este modelo" que dispara `from_template/2`.
  """
  @spec library(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def library(conn, _params) do
    project = current_project(conn)
    brand = Keila.Projects.Brand.get(project)
    # Cache-buster: muda quando o brand muda, forcando iframes a recarregar
    brand_version = brand_hash(brand)

    conn
    |> assign(:models, Library.list_models())
    |> assign(:brand_version, brand_version)
    |> put_meta(:title, gettext("Modelos de Email"))
    |> render("library.html")
  end

  defp brand_hash(brand) do
    [
      Map.get(brand, "color_primary"),
      Map.get(brand, "color_dark"),
      Map.get(brand, "color_accent"),
      Map.get(brand, "logo_url"),
      Map.get(brand, "name")
    ]
    |> Enum.join("|")
    |> :erlang.phash2()
    |> Integer.to_string()
  end

  @doc """
  Cria uma nova campanha pré-carregada com o MJML de um modelo da biblioteca.
  Redireciona pro editor com tudo pronto pra editar.
  """
  @spec from_template(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def from_template(conn, %{"slug" => slug}) do
    project = current_project(conn)

    with {:ok, model} <- Library.get_model(slug),
         {:ok, mjml_raw} <- Library.load_mjml(slug) do
      brand = Keila.Projects.Brand.get(project)
      mjml = Library.apply_brand(mjml_raw, brand)

      params = %{
        "subject" => Library.default_subject(slug),
        "mjml_body" => mjml,
        "settings" => %{"type" => "mjml"},
        "data" => %{"library_slug" => model.slug, "library_title" => model.title}
      }

      case Mailings.create_campaign(project.id, params) do
        {:ok, campaign} ->
          conn
          |> put_flash(:info, gettext("Modelo \"%{title}\" carregado. Edite à vontade!", title: model.title))
          |> redirect(to: Routes.campaign_path(conn, :edit, project.id, campaign.id))

        {:error, _changeset} ->
          conn
          |> put_flash(:error, gettext("Não foi possível criar a campanha a partir do modelo."))
          |> redirect(to: Routes.campaign_path(conn, :library, project.id))
      end
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:error, gettext("Modelo não encontrado."))
        |> redirect(to: Routes.campaign_path(conn, :library, project.id))

      {:error, _reason} ->
        conn
        |> put_flash(:error, gettext("Erro ao carregar o modelo."))
        |> redirect(to: Routes.campaign_path(conn, :library, project.id))
    end
  end

  @spec clone(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def clone(conn, _params) do
    render_clone(conn, change(conn.assigns.campaign))
  end

  @spec post_clone(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def post_clone(conn, params) do
    project = current_project(conn)
    campaign = conn.assigns.campaign
    params = params["campaign"] || %{}

    case Mailings.clone_campaign(campaign.id, params) do
      {:ok, campaign} ->
        redirect(conn, to: Routes.campaign_path(conn, :edit, project.id, campaign.id))

      {:error, changeset} ->
        render_clone(conn, 400, changeset)
    end
  end

  defp render_clone(conn, status \\ 200, changeset) do
    conn
    |> put_status(status)
    |> put_meta(:title, gettext("Clone Campaign"))
    |> assign(:changeset, changeset)
    |> render("clone.html")
  end

  @spec edit(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def edit(conn, _params) do
    project = current_project(conn)
    campaign = conn.assigns.campaign

    if is_nil(campaign.sent_at) do
      senders = Mailings.get_project_senders(project.id)
      templates = Templates.get_project_templates(project.id)
      segments = Contacts.get_project_segments(project.id)
      account = Keila.Accounts.get_user_account(conn.assigns.current_user.id)

      live_render(conn, KeilaWeb.CampaignEditLive,
        session: %{
          "current_project" => project,
          "campaign" => campaign,
          "senders" => senders,
          "templates" => templates,
          "segments" => segments,
          "account" => account,
          "locale" => Gettext.get_locale()
        }
      )
    else
      redirect(conn, to: Routes.campaign_path(conn, :stats, project.id, campaign.id))
    end
  end

  @spec stats(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def stats(conn, _params) do
    project = current_project(conn)
    campaign = conn.assigns.campaign
    account = Keila.Accounts.get_user_account(conn.assigns.current_user.id)

    live_render(conn, KeilaWeb.CampaignStatsLive,
      session: %{
        "current_project" => project,
        "campaign" => campaign,
        "account" => account,
        "locale" => Gettext.get_locale()
      }
    )
  end

  def view(conn, _params) do
    project = current_project(conn)
    campaign = conn.assigns.campaign

    preview =
      cond do
        is_binary(campaign.html_body) and campaign.html_body != "" ->
          campaign.html_body

        is_binary(campaign.text_body) and campaign.text_body != "" ->
          KeilaWeb.CampaignView.plain_text_preview(campaign.text_body)

        true ->
          safe_build_preview(campaign)
      end

    render(conn, "view.html", %{
      current_project: project,
      campaign: campaign,
      preview: preview
    })
  end

  defp safe_build_preview(campaign) do
    email = Keila.Mailings.Builder.build_preview(campaign)
    email.html_body || KeilaWeb.CampaignView.plain_text_preview(email.text_body)
  rescue
    e ->
      require Logger
      Logger.error("Failed to build campaign preview: #{Exception.format(:error, e, __STACKTRACE__)}")

      "<div style=\"padding:24px;font-family:sans-serif;color:#444\">" <>
        "<p><strong>Não foi possível gerar a pré-visualização desta campanha.</strong></p>" <>
        "<p>O corpo do email não está disponível ou o template foi removido.</p>" <>
        "</div>"
  end

  def share(conn, _params) do
    project = current_project(conn)
    campaign = conn.assigns.campaign

    render(conn, "share.html", %{
      current_project: project,
      campaign: campaign
    })
  end

  def post_share(conn, %{"enable" => raw_enable?}) do
    project = current_project(conn)

    enable? = String.to_existing_atom(raw_enable?)
    campaign_id = conn.assigns.campaign.id
    campaign = Mailings.enable_public_link!(campaign_id, enable?)

    render(conn, "share.html", %{
      current_project: project,
      campaign: campaign
    })
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, params) do
    ids =
      case get_in(params, ["campaign", "id"]) do
        ids when is_list(ids) -> ids
        id when is_binary(id) -> [id]
      end

    case get_in(params, ["campaign", "require_confirmation"]) do
      "true" ->
        render_delete_confirmation(conn, ids)

      _ ->
        :ok = Mailings.delete_project_campaigns(current_project(conn).id, ids)

        redirect(conn, to: Routes.campaign_path(conn, :index, current_project(conn).id))
    end
  end

  defp render_delete_confirmation(conn, ids) do
    campaigns =
      Mailings.get_project_campaigns(current_project(conn).id)
      |> Enum.filter(&(&1.id in ids))

    conn
    |> put_meta(:title, gettext("Confirm campaign Deletion"))
    |> assign(:campaigns, campaigns)
    |> render("delete.html")
  end

  defp current_project(conn), do: conn.assigns.current_project

  defp authorize(conn, _) do
    project_id = current_project(conn).id
    campaign_id = conn.path_params["id"]

    case Mailings.get_project_campaign(project_id, campaign_id) do
      nil ->
        conn
        |> put_status(404)
        |> halt()

      campaign ->
        assign(conn, :campaign, campaign)
    end
  end
end
