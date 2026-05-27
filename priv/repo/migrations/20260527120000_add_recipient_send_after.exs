defmodule Keila.Repo.Migrations.AddRecipientSendAfter do
  use Ecto.Migration

  def change do
    alter table("mailings_recipients") do
      # Horário em que este destinatário pode ser enfileirado pra envio.
      # nil = pode enfileirar já (comportamento padrão). Usado pelo envio em
      # ondas (cadência): cada destinatário recebe um horário e o ScheduleWorker
      # só o enfileira quando send_after já passou.
      add :send_after, :utc_datetime
    end

    # Índice parcial: o ScheduleWorker filtra por queued_at IS NULL e agora
    # também por send_after.
    create index("mailings_recipients", [:send_after],
             where: "queued_at IS NULL",
             name: :mailings_recipients_pending_send_after_index
           )
  end
end
