defmodule Keila.Mailings.RecipientActions do
  @moduledoc """
  Helpers compartilhados pelos handlers de evento de destinatário
  (`RecipientActions.HardBounce`, `.Complaint`, `.Unsubscription`, etc.).
  """
  use Keila.Repo

  alias Keila.Contacts.Contact

  @doc """
  Adiciona o e-mail de um contato à lista de supressão da empresa (trava dura
  de envio). Best-effort: nunca levanta exceção nem interrompe o fluxo do evento.

  `reason` ∈ `Keila.Suppressions.Suppression.reasons/0`
  (hard_bounce | complaint | unsubscribe | ...).
  """
  @spec suprimir_contato(term() | nil, String.t(), String.t() | nil) :: :ok
  def suprimir_contato(nil, _reason, _source), do: :ok

  def suprimir_contato(contact_id, reason, source) do
    case Repo.get(Contact, contact_id) do
      %Contact{email: email, project_id: project_id} when is_binary(email) ->
        _ =
          Keila.Suppressions.suprimir(email,
            project_id: project_id,
            reason: reason,
            source: source
          )

        :ok

      _ ->
        :ok
    end
  rescue
    _ -> :ok
  end
end
