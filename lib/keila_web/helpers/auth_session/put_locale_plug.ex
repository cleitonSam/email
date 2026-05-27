defmodule KeilaWeb.PutLocalePlug do
  @moduledoc """
  Plug for setting the Gettext locale.

  Resolution order:

    1. The `:current_user` assign, when it has a locale set.
    2. The `lang` query parameter (also persisted to the session).
    3. The locale stored in the session.
    4. The configured `:default_locale` (pt) as a fallback.

  The browser `accept-language` header is intentionally NOT used: this is a
  Portuguese-first product, so visitors default to pt unless they explicitly
  choose another language via `?lang=` or their user settings.
  """

  alias Keila.Auth.User

  @spec init(list()) :: list()
  def init(_), do: []

  @spec call(Plug.Conn.t(), list()) :: Plug.Conn.t()
  def call(conn, _opts) do
    case conn.assigns[:current_user] do
      %User{locale: locale} when is_binary(locale) ->
        put_locale(locale)
        conn

      _other ->
        put_locale_from_session(conn)
    end
  end

  defp put_locale(locale) do
    locales = Application.get_env(:keila, KeilaWeb.Gettext) |> Keyword.fetch!(:locales)

    if locale in locales do
      Gettext.put_locale(locale)
      :ok
    else
      :error
    end
  end

  defp put_locale_from_session(conn) do
    default_locale =
      Application.get_env(:keila, KeilaWeb.Gettext) |> Keyword.get(:default_locale, "pt")

    param_locale = conn.query_params["lang"]
    session_locale = Plug.Conn.get_session(conn, :locale)

    locale =
      [param_locale, session_locale, default_locale]
      |> Enum.find(fn locale -> put_locale(locale) == :ok end)

    if not is_nil(param_locale) and param_locale == locale do
      Plug.Conn.put_session(conn, :locale, locale)
    else
      conn
    end
  end
end
