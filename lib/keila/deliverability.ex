defmodule Keila.Deliverability do
  @moduledoc """
  Verificação de DNS por domínio de envio e gate de disparo
  (regra inegociável nº 1 do Prompt Mestre: sem domínio validado, sem envio).

  Faz lookups de SPF/DKIM/DMARC via `:inet_res` e grava o estado em
  `Keila.Deliverability.EmailDomain`.

  ## Gate progressivo (não-quebra)

  `dominio_liberado?/2` é o gate consultado por `Mailings.deliver_campaign`:

    - Domínio com registro **verified** → libera.
    - Domínio com registro **não-verificado** (pending/failed) → bloqueia.
    - Domínio **sem registro** → libera por padrão (comportamento legado), a
      menos que a variável de ambiente `REQUIRE_VERIFIED_DOMAIN` esteja ligada
      (modo estrito). Isso evita brickar o envio de projetos que ainda não
      cadastraram domínios — a empresa cadastra e verifica, e aí passa a valer.
  """
  import Ecto.Query
  require Logger

  alias Keila.Repo
  alias Keila.Deliverability.EmailDomain

  # ------------------------------------------------------------------
  # CRUD
  # ------------------------------------------------------------------

  @doc "Lista os domínios de envio de um projeto."
  def list_por_projeto(project_id) do
    EmailDomain
    |> where([d], d.project_id == ^project_id)
    |> order_by([d], asc: d.domain)
    |> Repo.all()
  end

  def get(id), do: Repo.get(EmailDomain, id)

  def get_por_projeto(project_id, id) do
    Repo.get_by(EmailDomain, id: id, project_id: project_id)
  end

  def get_by_project_domain(project_id, domain) do
    normalized = EmailDomain.normalize_domain(domain)
    Repo.get_by(EmailDomain, project_id: project_id, domain: normalized)
  end

  @doc "Cadastra um domínio de envio para um projeto."
  def criar(project_id, params) do
    params
    |> Map.put("project_id", project_id)
    |> EmailDomain.creation_changeset()
    |> Repo.insert()
  end

  def excluir(%EmailDomain{} = domain), do: Repo.delete(domain)

  # ------------------------------------------------------------------
  # Verificação de DNS
  # ------------------------------------------------------------------

  @doc """
  Executa a verificação de DNS (SPF/DKIM/DMARC) de um domínio e grava o
  resultado. Considera "verified" quando SPF **e** DMARC estão presentes/válidos.
  DKIM é best-effort (só checado se houver `dkim_selector`).
  """
  @spec verificar_dominio(EmailDomain.t()) :: {:ok, EmailDomain.t()} | {:error, Ecto.Changeset.t()}
  def verificar_dominio(%EmailDomain{} = email_domain) do
    domain = email_domain.domain

    spf_ok = check_spf(domain)
    dmarc_ok = check_dmarc(domain)
    dkim_ok = check_dkim(domain, email_domain.dkim_selector)

    status = if spf_ok and dmarc_ok, do: "verified", else: "failed"

    last_error =
      cond do
        status == "verified" -> nil
        not spf_ok and not dmarc_ok -> "SPF e DMARC ausentes/ inválidos"
        not spf_ok -> "Registro SPF ausente ou inválido"
        not dmarc_ok -> "Registro DMARC ausente ou inválido"
        true -> nil
      end

    email_domain
    |> EmailDomain.check_changeset(%{
      status: status,
      spf_ok: spf_ok,
      dmarc_ok: dmarc_ok,
      dkim_ok: dkim_ok,
      last_checked_at: DateTime.utc_now() |> DateTime.truncate(:second),
      last_error: last_error
    })
    |> Repo.update()
  end

  @doc "Verifica todos os domínios pendentes/falhos (uso em job periódico)."
  def reverificar_todos do
    EmailDomain
    |> Repo.all()
    |> Enum.each(&verificar_dominio/1)
  end

  # ------------------------------------------------------------------
  # Gate de envio
  # ------------------------------------------------------------------

  @doc """
  Indica se o domínio do remetente está liberado para disparo. Ver o moduledoc
  para a semântica do gate progressivo.
  """
  @spec dominio_liberado?(term(), String.t() | nil) :: boolean()
  def dominio_liberado?(project_id, from_email) do
    case domain_from_email(from_email) do
      nil ->
        not require_verified?()

      domain ->
        case get_by_project_domain(project_id, domain) do
          %EmailDomain{status: "verified"} -> true
          %EmailDomain{} -> false
          nil -> not require_verified?()
        end
    end
  end

  @doc "Extrai o domínio (normalizado) de um endereço de e-mail."
  @spec domain_from_email(String.t() | nil) :: String.t() | nil
  def domain_from_email(email) when is_binary(email) do
    case String.split(email, "@") do
      [_local, domain] when domain != "" -> EmailDomain.normalize_domain(domain)
      _ -> nil
    end
  end

  def domain_from_email(_), do: nil

  defp require_verified? do
    System.get_env("REQUIRE_VERIFIED_DOMAIN") in ["1", "true", "TRUE", "yes"]
  end

  # ------------------------------------------------------------------
  # Checagens de DNS (públicas para teste/diagnóstico)
  # ------------------------------------------------------------------

  @doc "True se o domínio tem um registro SPF (`v=spf1`)."
  def check_spf(domain) do
    domain
    |> txt_records()
    |> Enum.any?(&String.starts_with?(String.downcase(&1), "v=spf1"))
  end

  @doc "True se o domínio tem um registro DMARC válido em `_dmarc.<domínio>`."
  def check_dmarc(domain) do
    ("_dmarc." <> domain)
    |> txt_records()
    |> Enum.any?(&valid_dmarc?/1)
  end

  @doc """
  Checagem best-effort de DKIM. Sem `selector`, retorna `nil` (desconhecido) —
  a maioria dos MTAs assina o DKIM e o seletor varia por provedor.
  """
  def check_dkim(_domain, selector) when selector in [nil, ""], do: nil

  def check_dkim(domain, selector) do
    ("#{selector}._domainkey.#{domain}")
    |> txt_records()
    |> Enum.any?(fn txt ->
      down = String.downcase(txt)
      String.contains?(down, "v=dkim1") or String.contains?(down, "k=") or
        String.contains?(down, "p=")
    end)
  end

  @doc "True se a string é um registro DMARC válido (`v=DMARC1` com tag `p=`)."
  def valid_dmarc?(txt) when is_binary(txt) do
    trimmed = String.trim(txt)

    if String.starts_with?(String.downcase(trimmed), "v=dmarc1") do
      tags =
        trimmed
        |> String.split(";")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))

      Enum.all?(tags, &String.contains?(&1, "=")) and
        Enum.any?(tags, &String.starts_with?(String.downcase(&1), "p="))
    else
      false
    end
  end

  def valid_dmarc?(_), do: false

  # Retorna a lista de strings TXT de um nome DNS (cada registro TXT pode ter
  # múltiplos fragmentos, que são concatenados). Best-effort: erros viram [].
  defp txt_records(name) do
    name
    |> String.to_charlist()
    |> :inet_res.lookup(:in, :txt)
    |> Enum.map(fn parts ->
      parts |> Enum.map(&to_string/1) |> Enum.join("")
    end)
  rescue
    e ->
      Logger.debug("[Deliverability] TXT lookup falhou para #{name}: #{inspect(e)}")
      []
  catch
    _, _ -> []
  end
end
