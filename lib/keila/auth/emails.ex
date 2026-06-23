defmodule Keila.Auth.Emails do
  # FIXME Don't depend on Web App here
  use KeilaWeb.Gettext
  import Swoosh.Email

  @spec send!(atom(), map()) :: term() | no_return()
  def send!(email, params) do
    config = Application.get_env(:keila, __MODULE__, [])

    email
    |> build(params)
    |> Keila.Mailer.deliver!(config)
  end

  @spec build(:activate, %{url: String.t(), user: Keila.Auth.User.t()}) :: term() | no_return()
  def build(:activate, %{user: user, url: url}) do
    new()
    |> from({"Fluxo Digital", system_from_email()})
    |> subject(dgettext("auth", "Please Verify Your Account"))
    |> to(user.email)
    |> text_body(
      dgettext(
        "auth",
        """
        Welcome to Fluxo Digital,

        please confirm your new account by visiting the following link:

        %{url}

        If you weren’t trying to create an account, simply ignore this message.
        """,
        url: url
      )
    )
  end

  @spec build(:update_email, %{url: String.t(), user: Keila.Auth.User.t()}) ::
          term() | no_return()
  def build(:update_email, %{user: user, url: url}) do
    new()
    |> from({"Fluxo Digital", system_from_email()})
    |> subject(dgettext("auth", "Please Verify Your Email"))
    |> to(user.email)
    |> text_body(
      dgettext(
        "auth",
        """
        Hey there,

        please confirm your new email address by visiting the following link:

        %{url}

        If you weren’t trying to change your email address, simply ignore this message.
        """,
        url: url
      )
    )
  end

  @spec build(:password_reset_link, %{url: String.t(), user: Keila.Auth.User.t()}) ::
          term() | no_return()
  def build(:password_reset_link, %{user: user, url: url}) do
    new()
    |> subject(dgettext("auth", "Your Account Reset Link"))
    |> to(user.email)
    |> from({"Fluxo Digital", system_from_email()})
    |> text_body(
      dgettext(
        "auth",
        """
        Hey there,

        you have requested a password reset for your Fluxo Digital account.

        You can set a new password by visiting the following link:

        %{url}

        If you weren’t trying to reset your password, simply ignore this message.
        """,
        url: url
      )
    )
  end

  @spec build(:login_link, %{url: String.t(), user: Keila.Auth.User.t()}) :: term() | no_return()
  def build(:login_link, %{user: user, url: url}) do
    new()
    |> subject(dgettext("auth", "Your Login Link"))
    |> to(user.email)
    |> from({"Fluxo Digital", system_from_email()})
    |> text_body(
      dgettext(
        "auth",
        """
        Hey there,

        you can login to Fluxo Digital with the following link:

        %{url}

        If you haven’t requested a login, simply ignore this message.
        """,
        url: url
      )
    )
  end

  @spec build(:verify_sender_from_email, %{url: String.t(), sender: Keila.Mailings.Sender.t()}) ::
          term() | no_return()
  def build(:verify_sender_from_email, %{sender: sender, url: url}) do
    new()
    |> subject(dgettext("auth", "Please Verify Your Email for Fluxo Digital"))
    |> to(sender.from_email)
    |> from({"Fluxo Digital", system_from_email()})
    |> text_body(
      dgettext(
        "auth",
        """
        Hey there,

        please verify your sender email address by visiting the following link:

        %{url}

        If you didn't request this verification, please ignore this message and
        do not click on the link.
        """,
        url: url
      )
    )
  end

  @spec build(:invitation, %{
          url: String.t(),
          email: String.t(),
          inviter: String.t(),
          project_name: String.t()
        }) :: term() | no_return()
  def build(:invitation, %{url: url, inviter: inviter, project_name: project_name} = params) do
    email = params.email
    brand = Map.get(params, :brand, %{})
    primary = Map.get(brand, :color_primary) || "#0066FF"
    dark = Map.get(brand, :color_dark) || "#0A1F3D"
    accent = Map.get(brand, :color_accent) || "#00F2FE"
    logo_url = Map.get(brand, :logo_url)

    new()
    |> from({"#{project_name} via Fluxo", system_from_email()})
    |> subject("Você foi convidado pro #{project_name} no Fluxo")
    |> to(email)
    |> text_body(invitation_text(url, inviter, project_name))
    |> html_body(invitation_html(url, inviter, project_name, logo_url, primary, dark, accent))
  end

  defp invitation_text(url, inviter, project_name) do
    """
    Olá!

    #{inviter} convidou você para fazer parte de "#{project_name}" no Fluxo.

    Para aceitar o convite e criar sua conta, acesse o link abaixo:

    #{url}

    Esse link vale por 7 dias.

    Se você não esperava este convite, pode ignorar este e-mail com tranquilidade.

    — Fluxo Digital
    """
  end

  defp invitation_html(url, inviter, project_name, logo_url, primary, dark, accent) do
    inviter_e = esc(inviter)
    project_e = esc(project_name)

    logo_block =
      if is_binary(logo_url) and logo_url != "" do
        ~s(<img src="#{logo_url}" alt="#{project_e}" width="160" style="max-width:160px;height:auto;display:block;margin:0 auto;border:0;" />)
      else
        ~s(<span style="font-size:22px;font-weight:bold;color:#ffffff;letter-spacing:.3px;">#{project_e}</span>)
      end

    """
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>Convite — Fluxo</title>
    </head>
    <body style="margin:0;padding:0;background:#f4f6fb;font-family:Helvetica,Arial,sans-serif;color:#1a1a1a;">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4f6fb;padding:24px 0;">
        <tr>
          <td align="center">
            <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(10,31,61,.08);">
              <tr><td style="height:4px;background:#{accent};font-size:0;line-height:0;">&nbsp;</td></tr>
              <tr>
                <td align="center" style="background:#{dark};padding:32px 24px;">
                  #{logo_block}
                </td>
              </tr>
              <tr>
                <td style="padding:36px 40px 8px;">
                  <h1 style="margin:0 0 12px;font-size:22px;line-height:1.3;color:#0a1f3d;">Você foi convidado 🎉</h1>
                  <p style="margin:0 0 22px;font-size:15px;line-height:1.6;color:#3a4a63;">
                    <strong>#{inviter_e}</strong> convidou você para fazer parte de <strong>#{project_e}</strong> no Fluxo.
                  </p>
                </td>
              </tr>
              <tr>
                <td align="center" style="padding:0 40px 26px;">
                  <table role="presentation" cellpadding="0" cellspacing="0">
                    <tr>
                      <td align="center" bgcolor="#{primary}" style="border-radius:10px;">
                        <a href="#{url}" target="_blank" style="display:inline-block;padding:14px 34px;font-size:16px;font-weight:bold;color:#ffffff;text-decoration:none;border-radius:10px;">Aceitar convite &rarr;</a>
                      </td>
                    </tr>
                  </table>
                  <p style="margin:16px 0 0;font-size:12px;color:#8a98ad;">Esse link vale por 7 dias.</p>
                </td>
              </tr>
              <tr>
                <td style="padding:0 40px 30px;">
                  <p style="margin:0 0 6px;font-size:12px;color:#8a98ad;">Se o botão não funcionar, copie e cole este endereço no navegador:</p>
                  <p style="margin:0;font-size:12px;word-break:break-all;"><a href="#{url}" style="color:#{primary};text-decoration:underline;">#{url}</a></p>
                </td>
              </tr>
              <tr>
                <td style="background:#f4f6fb;padding:20px 40px;border-top:1px solid #e6eaf1;">
                  <p style="margin:0;font-size:12px;line-height:1.5;color:#8a98ad;">
                    Se você não esperava este convite, pode ignorar este e-mail com tranquilidade.<br />
                    — Fluxo Digital · plataforma de e-mail marketing
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
    """
  end

  defp esc(nil), do: ""

  defp esc(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  defp system_from_email() do
    Application.get_env(:keila, __MODULE__) |> Keyword.fetch!(:from_email)
  end
end
