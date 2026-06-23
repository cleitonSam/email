defmodule Keila.Contacts.EmailHygiene do
  @moduledoc """
  Higiene de e-mail para import/cadastro (LGPD § 4 / regra nº 4 do Prompt Mestre):
  sintaxe, domínios descartáveis e MX.

  - `disposable?/1` e `valid_syntax?/1` são puros e rápidos (uso inline no import).
  - `valid_mx?/1` faz lookup DNS (best-effort) — use fora do caminho quente.
  - `classify/1` combina sintaxe + descartável (sem rede) e retorna o motivo.
  """

  @syntax_regex ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  # Lista curada de domínios descartáveis/temporários mais comuns. Não é
  # exaustiva — serve para barrar o grosso de bases compradas/raspadas.
  @disposable_domains MapSet.new(~w(
    mailinator.com guerrillamail.com guerrillamailblock.com sharklasers.com
    10minutemail.com 10minutemail.net tempmail.com temp-mail.org tempmail.net
    throwawaymail.com throwaway.email yopmail.com yopmail.net getnada.com
    nada.email dispostable.com trashmail.com trashmail.net mailnesia.com
    fakeinbox.com maildrop.cc mintemail.com mohmal.com mytemp.email
    spamgourmet.com tempinbox.com tempr.email emailondeck.com burnermail.io
    moakt.com inboxbear.com tempmailo.com fakemail.net discard.email
  ))

  @doc "Extrai o domínio (minúsculo) de um e-mail, ou `nil`."
  @spec domain(String.t() | nil) :: String.t() | nil
  def domain(email) when is_binary(email) do
    case email |> String.trim() |> String.downcase() |> String.split("@") do
      [_local, d] when d != "" -> d
      _ -> nil
    end
  end

  def domain(_), do: nil

  @doc "Validação de sintaxe básica (presença de @ e domínio com ponto)."
  @spec valid_syntax?(String.t() | nil) :: boolean()
  def valid_syntax?(email) when is_binary(email), do: String.match?(String.trim(email), @syntax_regex)
  def valid_syntax?(_), do: false

  @doc "True se o domínio do e-mail é descartável/temporário conhecido."
  @spec disposable?(String.t() | nil) :: boolean()
  def disposable?(email) do
    case domain(email) do
      nil -> false
      d -> MapSet.member?(@disposable_domains, d)
    end
  end

  @doc """
  Verifica (best-effort) se o domínio do e-mail tem registro MX. Erros de rede
  são tratados como `false`. Faz lookup DNS — não usar no caminho quente.
  """
  @spec valid_mx?(String.t() | nil) :: boolean()
  def valid_mx?(email) do
    case domain(email) do
      nil ->
        false

      d ->
        d
        |> String.to_charlist()
        |> :inet_res.lookup(:in, :mx)
        |> case do
          [] -> false
          list when is_list(list) -> true
          _ -> false
        end
    end
  rescue
    _ -> false
  catch
    _, _ -> false
  end

  @doc """
  Classifica um e-mail (sem rede): `:ok`, `:invalid_syntax` ou `:disposable`.
  """
  @spec classify(String.t() | nil) :: :ok | :invalid_syntax | :disposable
  def classify(email) do
    cond do
      not valid_syntax?(email) -> :invalid_syntax
      disposable?(email) -> :disposable
      true -> :ok
    end
  end

  @doc "Lista de domínios descartáveis conhecidos (para diagnóstico/testes)."
  def disposable_domains, do: @disposable_domains
end
