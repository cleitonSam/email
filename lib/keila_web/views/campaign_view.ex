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

  @doc """
  Retorna true se a campanha está usando "envio em ondas" (cadência) —
  campaign.data["cadence"]["slots"] é uma lista não-vazia.
  """
  def has_cadence?(%{data: %{"cadence" => %{"slots" => slots}}}) when is_list(slots) and slots != [],
    do: true

  def has_cadence?(_), do: false

  @doc """
  Quantos slots de cadência a campanha tem configurados (0 se não tem).
  """
  def cadence_slot_count(%{data: %{"cadence" => %{"slots" => slots}}}) when is_list(slots),
    do: length(slots)

  def cadence_slot_count(_), do: 0

  @doc """
  Config de repetição da campanha (`data["repeat"]`) ou nil.
  """
  def repeat_config(%{data: %{"repeat" => %{"interval_days" => days} = repeat}})
      when is_integer(days) and days > 0,
      do: repeat

  def repeat_config(_), do: nil

  @doc """
  Descrição curta da repetição pra exibir no card, ou nil.
  Ex.: "Repete a cada 7 dias" / "Repete a cada 15 dias até 31/12/2026".
  """
  def repeat_label(campaign) do
    case repeat_config(campaign) do
      %{"interval_days" => days} = repeat ->
        until =
          case Date.from_iso8601(to_string(repeat["until_date"] || "")) do
            {:ok, date} -> " até #{Calendar.strftime(date, "%d/%m/%Y")}"
            _ -> ""
          end

        "Repete a cada #{days} #{if days == 1, do: "dia", else: "dias"}#{until}"

      nil ->
        nil
    end
  end
end
