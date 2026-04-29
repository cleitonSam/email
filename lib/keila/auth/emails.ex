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
    |> from({"Keila", system_from_email()})
    |> subject(dgettext("auth", "Please Verify Your Account"))
    |> to(user.email)
    |> text_body(
      dgettext(
        "auth",
        """
        Welcome to Keila,

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
    |> from({"Keila", system_from_email()})
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
    |> from({"Keila", system_from_email()})
    |> text_body(
      dgettext(
        "auth",
        """
        Hey there,

        you have requested a password reset for your Keila account.

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
    |> from({"Keila", system_from_email()})
    |> text_body(
      dgettext(
        "auth",
        """
        Hey there,

        you can login to Keila with the following link:

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
    |> subject(dgettext("auth", "Please Verify Your Email for Keila"))
    |> to(sender.from_email)
    |> from({"Keila", system_from_email()})
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
  def build(:invitation, %{url: url, email: email, inviter: inviter, project_name: project_name}) do
    new()
    |> from({"Fluxo Email MKT", system_from_email()})
    |> subject("Você foi convidado pro #{project_name} no Fluxo")
    |> to(email)
    |> text_body("""
    Olá!

    #{inviter} convidou você pra fazer parte do projeto "#{project_name}" no Fluxo Email MKT.

    Pra aceitar o convite e criar sua conta, clica no link abaixo:

    #{url}

    Esse link vale por 7 dias.

    Se você não esperava esse convite, pode ignorar este email com tranquilidade.

    --
    Fluxo Email MKT
    Email Marketing pra Academias
    """)
  end

  defp system_from_email() do
    Application.get_env(:keila, __MODULE__) |> Keyword.fetch!(:from_email)
  end
end
