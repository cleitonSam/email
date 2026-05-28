defmodule Keila.Mailings.Worker do
  @moduledoc """
  This worker builds and delivers queued emails.
  """
  use Keila.Repo

  use Oban.Worker,
    queue: :mailer,
    max_attempts: 5,
    unique: [
      period: :infinity,
      states: [:available, :scheduled, :executing, :retryable],
      fields: [:args],
      keys: [:recipient_id]
    ]

  alias Keila.Contacts.Contact
  alias Keila.Mailings.{Recipient, Builder, RateLimiter}

  require Logger

  # Backoff em segundos: 30, 60, 120, 240 (caps em 5min) para retries de erro
  # transient. Snooze (rate limit) tem seu próprio delay, não passa por aqui.
  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}) do
    base = 30
    min(base * Integer.pow(2, attempt - 1), 300)
  end

  @impl true
  def perform(%Oban.Job{args: %{"recipient_id" => recipient_id}} = job) do
    case load_recipient(recipient_id) do
      nil ->
        Logger.warning("Skipping mailer job: recipient #{inspect(recipient_id)} not found.")
        {:cancel, :recipient_not_found}

      recipient ->
        with :ok <- check_sender_rate_limit(recipient, job),
             :ok <- ensure_valid_recipient(recipient),
             email <- Builder.build(recipient.campaign, recipient, %{}),
             :ok <- ensure_valid_email(email) do
          Keila.Mailer.deliver_with_sender(email, recipient.campaign.sender)
        end
        |> handle_result(recipient, job)
    end
  end

  defp load_recipient(recipient_id) do
    from(r in Recipient,
      where: r.id == ^recipient_id,
      preload: [contact: [], campaign: [[sender: [:shared_sender]], :template]]
    )
    |> Repo.one()
  end

  defp ensure_valid_recipient(%{contact: %{status: :active, email: email}, sent_at: nil})
       when not is_nil(email),
       do: :ok

  defp ensure_valid_recipient(%{sent_at: sent_at}) when not is_nil(sent_at),
    do: {:error, :already_sent}

  defp ensure_valid_recipient(_recipient), do: {:error, :invalid_contact}

  defp check_sender_rate_limit(recipient, job) do
    scheduling_requested_at = scheduling_requested_at(job)

    case RateLimiter.check_sender_rate_limit(recipient.campaign.sender, scheduling_requested_at) do
      :ok ->
        :ok

      {:error, {schedule_at, scheduling_requested_at}} ->
        job.args
        |> Map.put("scheduling_requested_at", scheduling_requested_at)
        |> __MODULE__.new(replace: [executing: [:args]])
        |> Oban.insert!()

        delay = DateTime.diff(schedule_at, scheduling_requested_at)

        log_snooze(recipient, delay)

        {:snooze, delay}
    end
  end

  # Log apenas o primeiro snooze por campanha em cada janela de 60s pra não floodar
  # o log quando centenas de jobs batem o rate limit ao mesmo tempo. Tracking
  # via :persistent_term que sobrevive a múltiplas workers do mesmo node.
  defp log_snooze(recipient, delay) do
    campaign_id = recipient.campaign.id
    key = {__MODULE__, :snooze_log, campaign_id}
    now = System.monotonic_time(:second)

    last =
      try do
        :persistent_term.get(key)
      rescue
        ArgumentError -> 0
      end

    if now - last >= 60 do
      :persistent_term.put(key, now)

      Logger.info(
        "Mailer rate limit hit for campaign #{campaign_id} — snoozing recipients for ~#{delay}s. Subsequent snoozes in the next 60s are suppressed."
      )
    else
      Logger.debug(
        "Snoozing email to #{recipient.contact.email} for campaign #{campaign_id} for #{delay}s."
      )
    end
  end

  defp scheduling_requested_at(%{args: %{"scheduling_requested_at" => scheduling_requested_at}})
       when is_binary(scheduling_requested_at) do
    case DateTime.from_iso8601(scheduling_requested_at) do
      {:ok, scheduling_requested_at, 0} -> scheduling_requested_at
      _other -> nil
    end
  end

  defp scheduling_requested_at(_job), do: nil

  defp ensure_valid_email(email) do
    if Enum.find(email.headers, fn {name, _} -> name == "X-Keila-Invalid" end) do
      {:error, :rendering_error}
    else
      :ok
    end
  end

  # Email was sent successfully
  defp handle_result({:ok, raw_receipt}, recipient, _job) do
    receipt = get_receipt(raw_receipt)

    recipient
    |> set_recipient_sent_query(receipt)
    |> Repo.update_all([])

    :ok
  end

  # Sending needs to be retried later
  defp handle_result({:snooze, delay}, _recipient, _job), do: {:snooze, delay}

  # Email was already sent
  defp handle_result({:error, :already_sent}, _recipient, _job), do: {:cancel, :already_sent}

  # Rendering error
  defp handle_result({:error, :rendering_error}, recipient, _job) do
    Repo.transaction(fn ->
      recipient
      |> set_recipient_failed_query()
      |> Repo.update_all([])
    end)

    {:cancel, :rendering_error}
  end

  # Invalid contact (e.g. unsubscribed or deleted)
  defp handle_result({:error, :invalid_contact}, recipient, _job) do
    Repo.transaction(fn ->
      recipient
      |> set_recipient_failed_query()
      |> Repo.update_all([])

      recipient
      |> set_contact_unreachable_query()
      |> Repo.update_all([])
    end)

    {:cancel, :invalid_contact}
  end

  # Invalid email address (returned by Keila.Mailer)
  defp handle_result({:error, :invalid_email}, recipient, _job) do
    Repo.transaction(fn ->
      recipient
      |> set_recipient_failed_query()
      |> Repo.update_all([])

      recipient
      |> set_contact_unreachable_query()
      |> Repo.update_all([])
    end)

    {:cancel, :invalid_email}
  end

  # Another error occurred — retry transient errors (timeout/network/SMTP 4xx)
  # via Oban (até max_attempts). Erros permanentes marcam falha imediatamente.
  defp handle_result({:error, reason}, recipient, job) do
    attempt = Map.get(job, :attempt, 1)
    max_attempts = Map.get(job, :max_attempts, 5)

    cond do
      transient_error?(reason) and attempt < max_attempts ->
        Logger.warning(
          "Transient send error for #{recipient.contact.email} (campaign #{recipient.campaign.id}, attempt #{attempt}/#{max_attempts}): #{inspect(reason)} — Oban will retry"
        )

        {:error, reason}

      true ->
        Logger.warning(
          "Failed sending email to #{recipient.contact.email} for campaign #{recipient.campaign.id} (attempt #{attempt}): #{inspect(reason)}"
        )

        recipient
        |> set_recipient_failed_query()
        |> Repo.update_all([])

        {:cancel, reason}
    end
  end

  # Heurística pra classificar erros que valem retry — falhas de rede, timeout,
  # códigos HTTP 5xx, SMTP temporário (4xx). Erros permanentes (DNS inexistente,
  # auth inválido, address parse) caem no fallthrough e marcam o recipient.
  defp transient_error?(:timeout), do: true
  defp transient_error?(:closed), do: true
  defp transient_error?(:econnrefused), do: true
  defp transient_error?(:econnreset), do: true
  defp transient_error?(:enetunreach), do: true
  defp transient_error?(:ehostunreach), do: true
  defp transient_error?({:tls_alert, _}), do: true
  defp transient_error?({:failed_connect, _}), do: true

  defp transient_error?({code, _}) when is_integer(code) and code >= 500 and code < 600,
    do: true

  # SMTP 4xx é "tente de novo mais tarde"; 5xx é falha permanente.
  defp transient_error?({:retries_exceeded, {:network_failure, _, _}}), do: true
  defp transient_error?({:permanent_failure, _, _}), do: false
  defp transient_error?({:temporary_failure, _, _}), do: true

  defp transient_error?(%{__exception__: true} = e) do
    case e do
      %{__struct__: Mint.TransportError} -> true
      %{__struct__: Mint.HTTPError} -> true
      %{__struct__: Swoosh.DeliveryError, reason: reason} -> transient_error?(reason)
      _ -> false
    end
  end

  defp transient_error?(_), do: false

  defp set_recipient_sent_query(recipient, receipt) do
    from(r in Recipient,
      where: r.id == ^recipient.id,
      update: [
        set: [
          sent_at: fragment("NOW()"),
          receipt: ^receipt
        ]
      ]
    )
  end

  defp set_recipient_failed_query(recipient) do
    from(r in Recipient,
      where: r.id == ^recipient.id,
      update: [
        set: [
          failed_at: fragment("NOW()")
        ]
      ]
    )
  end

  defp set_contact_unreachable_query(%{contact_id: contact_id}) when not is_nil(contact_id) do
    from(c in Contact,
      where: c.id == ^contact_id,
      update: [
        set: [
          status: :unreachable,
          updated_at: fragment("NOW()")
        ]
      ]
    )
  end

  defp set_contact_unreachable_query(_), do: :ok

  defp get_receipt(%{id: receipt}), do: receipt
  defp get_receipt(receipt) when is_binary(receipt), do: receipt
  defp get_receipt(_), do: nil
end
