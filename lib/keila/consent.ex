defmodule Keila.Consent do
  @moduledoc """
  Prova de consentimento e base legal dos contatos (LGPD § 4 do Prompt Mestre).

  Grava registros imutáveis em `consent_logs` (o que foi exibido, versão da
  política, IP, user-agent, momento) para comprovar a base legal de tratamento
  de cada contato.

  A gravação é best-effort: uma falha ao registrar consentimento **nunca** deve
  derrubar o cadastro/import do contato.
  """
  import Ecto.Query
  require Logger

  alias Keila.Repo
  alias Keila.Consent.Log

  @doc """
  Registra uma prova de consentimento.

  ## Opções
    - `:contact` (ou `:contact_id`) — contato relacionado
    - `:project_id`
    - `:legal_basis` — consent | legitimate_interest | contract (default "consent")
    - `:source` — form | import | api | manual | integration
    - `:policy_version`, `:policy_url`, `:consent_text`
    - `:double_opt_in` (boolean)
    - `:ip`, `:user_agent`
    - `:occurred_at` (default: agora)
  """
  @spec registrar(keyword()) :: {:ok, Log.t()} | :error
  def registrar(opts) do
    {contact_id, email, project_id} = contact_fields(opts)

    params = %{
      contact_id: contact_id,
      project_id: opts[:project_id] || project_id,
      email: opts[:email] || email,
      legal_basis: opts[:legal_basis] || "consent",
      source: opts[:source],
      policy_version: opts[:policy_version],
      policy_url: opts[:policy_url],
      consent_text: opts[:consent_text],
      double_opt_in: opts[:double_opt_in] || false,
      ip: opts[:ip],
      user_agent: truncate(opts[:user_agent], 500),
      occurred_at: opts[:occurred_at] || now()
    }

    try do
      case params |> Log.changeset() |> Repo.insert() do
        {:ok, log} ->
          {:ok, log}

        {:error, changeset} ->
          Logger.error("[Consent] Falha ao registrar: #{inspect(changeset.errors)}")
          :error
      end
    rescue
      e ->
        Logger.error("[Consent] Exceção ao registrar: #{inspect(e)}")
        :error
    end
  end

  @doc "Histórico de consentimento de um contato (mais recente primeiro)."
  @spec historico_por_contato(term()) :: [Log.t()]
  def historico_por_contato(contact_id) do
    Log
    |> where([l], l.contact_id == ^contact_id)
    |> order_by([l], desc: l.occurred_at)
    |> Repo.all()
  end

  defp contact_fields(opts) do
    case opts[:contact] do
      %{id: id, email: email, project_id: project_id} -> {id, email, project_id}
      _ -> {opts[:contact_id], nil, nil}
    end
  end

  defp truncate(nil, _), do: nil
  defp truncate(str, max) when is_binary(str), do: String.slice(str, 0, max)
  defp truncate(other, _), do: other

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)
end
