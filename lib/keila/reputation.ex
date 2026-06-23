defmodule Keila.Reputation do
  @moduledoc """
  Monitoramento de reputação e **pausa automática** por limiar
  (regras inegociáveis nº 5 e 6 do Prompt Mestre).

  Calcula as taxas de reclamação de spam, hard bounce e descadastro de uma
  campanha e, ao ultrapassar o limiar seguro, **bloqueia a empresa** (que por sua
  vez barra novos disparos via `Keila.Empresas.pode_enviar?/1` no worker).

  Limiares (alvo de spam < 0,1%, teto duro < 0,3% — Gmail/Yahoo):
    - spam (complaint)  > 0,3%
    - hard bounce       > 5%
  Só avalia com amostra mínima (`@min_sample`) para não pausar por ruído.
  """
  import Ecto.Query
  require Logger

  alias Keila.Repo
  alias Keila.Mailings.{Recipient, Campaign}

  @spam_threshold 0.003
  @hard_bounce_threshold 0.05
  @min_sample 500

  @doc "Métricas absolutas + taxas de uma campanha."
  @spec campaign_metrics(term()) :: map()
  def campaign_metrics(campaign_id) do
    from(r in Recipient,
      where: r.campaign_id == ^campaign_id,
      select: %{
        sent: count(r.sent_at),
        complaints: count(r.complaint_received_at),
        hard_bounces: count(r.hard_bounce_received_at),
        unsubscribes: count(r.unsubscribed_at)
      }
    )
    |> Repo.one()
    |> with_rates()
  end

  @doc """
  Classifica uma métrica como violação de limiar (pura, sem efeitos).
  Retorna `nil`, `"spam"` ou `"bounce"`. Respeita a amostra mínima.
  """
  @spec breach(map()) :: nil | String.t()
  def breach(%{sent: sent}) when sent < @min_sample, do: nil

  def breach(%{spam_rate: spam}) when spam > @spam_threshold, do: "spam"
  def breach(%{hard_bounce_rate: hb}) when hb > @hard_bounce_threshold, do: "bounce"
  def breach(_), do: nil

  @doc """
  Avalia uma campanha e pausa a empresa se houver violação de limiar.
  Best-effort: nunca levanta exceção (chamado de handlers de evento).
  """
  @spec evaluate_campaign(term()) :: :ok | :error
  def evaluate_campaign(campaign_id) do
    metrics = campaign_metrics(campaign_id)

    case breach(metrics) do
      nil -> :ok
      motivo -> auto_pause(campaign_id, motivo, metrics)
    end
  rescue
    e ->
      Logger.error("[Reputation] Falha ao avaliar campanha #{inspect(campaign_id)}: #{inspect(e)}")
      :error
  end

  @doc "Limiares vigentes (para exibição/diagnóstico)."
  def thresholds,
    do: %{spam: @spam_threshold, hard_bounce: @hard_bounce_threshold, min_sample: @min_sample}

  defp auto_pause(campaign_id, motivo, metrics) do
    campaign = Repo.get(Campaign, campaign_id)
    empresa = campaign && Keila.Empresas.get_empresa_por_projeto(campaign.project_id)

    case empresa do
      %Keila.Empresas.Empresa{status: "bloqueada"} ->
        :ok

      %Keila.Empresas.Empresa{} = e ->
        Keila.Empresas.bloquear(e)

        Keila.Auditoria.registrar("empresa.pausada_automaticamente",
          entity: e,
          project_id: campaign.project_id,
          metadata: %{
            motivo: motivo,
            campaign_id: to_string(campaign_id),
            spam_rate: round4(metrics.spam_rate),
            hard_bounce_rate: round4(metrics.hard_bounce_rate),
            sent: metrics.sent
          }
        )

        Logger.warning(
          "[Reputation] Empresa #{inspect(e.id)} pausada automaticamente (#{motivo}) — " <>
            "spam=#{round4(metrics.spam_rate)} bounce=#{round4(metrics.hard_bounce_rate)} sent=#{metrics.sent}"
        )

        :ok

      _ ->
        :ok
    end
  end

  defp with_rates(%{sent: 0} = m),
    do: Map.merge(m, %{spam_rate: 0.0, hard_bounce_rate: 0.0, unsubscribe_rate: 0.0})

  defp with_rates(%{sent: sent} = m) do
    Map.merge(m, %{
      spam_rate: m.complaints / sent,
      hard_bounce_rate: m.hard_bounces / sent,
      unsubscribe_rate: m.unsubscribes / sent
    })
  end

  defp round4(float) when is_float(float), do: Float.round(float, 4)
  defp round4(other), do: other
end
