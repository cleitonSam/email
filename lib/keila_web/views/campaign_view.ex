defmodule KeilaWeb.CampaignView do
  use KeilaWeb, :view
  require Keila
  import Ecto.Changeset, only: [get_field: 2]

  def plain_text_preview(text) do
    """
    <!doctype html>
    <html>
      <head><meta charset="utf-8"/></head>
      <body style="margin: 0; padding: 20px; background: #eee; font-family: mono;;">
        <div style="max-width: 80ch; margin: 0 auto; padding: 20px;background: white; white-space: pre-line">
    #{text}
        </div>
      </body>
    </html>
    """
  end

  @doc """
  Determina o estado visível da campanha pro index, considerando contadores
  agregados de recipients (campos virtuais setados em get_project_campaigns_with_progress).

  Estados:
    * `:draft` - sem agendamento e sem disparo
    * `:scheduled` - agendado pra um horário futuro
    * `:overdue` - agendado mas o horário já passou (cron ainda não pegou ou está atrasado)
    * `:sending` - disparo iniciado mas ainda tem recipients pendentes
    * `:sent` - todos os recipients processados (enviados ou marcados como falha)
  """
  def campaign_progress_state(campaign) do
    now = DateTime.utc_now()
    recipients_count = Map.get(campaign, :recipients_count, 0)
    sent_count = Map.get(campaign, :sent_count, 0)
    failed_count = Map.get(campaign, :failed_count, 0)
    processed = sent_count + failed_count

    cond do
      campaign.sent_at && (recipients_count == 0 || processed >= recipients_count) ->
        :sent

      campaign.sent_at ->
        :sending

      campaign.scheduled_for && DateTime.compare(campaign.scheduled_for, now) == :gt ->
        :scheduled

      campaign.scheduled_for ->
        :overdue

      true ->
        :draft
    end
  end

  @doc """
  Retorna true se há ao menos uma campanha "viva" (enviando ou atrasada) que
  vale ficar atualizando a UI por.
  """
  def any_campaign_in_progress?(campaigns) do
    Enum.any?(campaigns, fn c ->
      campaign_progress_state(c) in [:sending, :overdue]
    end)
  end
end
