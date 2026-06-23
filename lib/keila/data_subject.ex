defmodule Keila.DataSubject do
  @moduledoc """
  Direitos do titular (Art. 18 LGPD — § 4 do Prompt Mestre): acesso, correção,
  portabilidade, eliminação/anonimização, revogação de consentimento, oposição.

  Inclui a **anonimização** de contato: remove o PII mantendo a linha para fins
  de auditoria/estatística, e adiciona o e-mail original à supressão para nunca
  mais ser contatado.
  """
  import Ecto.Query
  require Logger

  alias Keila.Repo
  alias Keila.DataSubject.Request
  alias Keila.Contacts.Contact

  @doc "Registra um pedido do titular. Tenta vincular ao contato pelo e-mail."
  @spec criar(term(), map()) :: {:ok, Request.t()} | {:error, Ecto.Changeset.t()}
  def criar(project_id, params) do
    params = Map.put(stringify(params), "project_id", project_id)

    contact_id =
      with email when is_binary(email) <- params["email"],
           %Contact{id: id} <- get_contact_by_email(project_id, email) do
        id
      else
        _ -> nil
      end

    params
    |> Map.put("contact_id", contact_id)
    |> Request.creation_changeset()
    |> Repo.insert()
  end

  @doc "Lista pedidos de um projeto (mais recentes primeiro)."
  def list_por_projeto(project_id) do
    Request
    |> where([r], r.project_id == ^project_id)
    |> order_by([r], desc: r.inserted_at)
    |> preload([:contact, :handled_by])
    |> Repo.all()
  end

  def get(id), do: Repo.get(Request, id) |> Repo.preload([:contact, :handled_by])

  @doc "Marca um pedido como concluído, registrando o atendente."
  def concluir(%Request{} = req, user_id) do
    req
    |> Request.status_changeset(%{
      status: "completed",
      handled_by_user_id: user_id,
      completed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end

  @doc "Marca um pedido como rejeitado."
  def rejeitar(%Request{} = req, user_id, motivo \\ nil) do
    req
    |> Request.status_changeset(%{status: "rejected", handled_by_user_id: user_id, details: motivo})
    |> Repo.update()
  end

  @doc """
  Anonimiza um contato (direito à eliminação/anonimização). Remove PII, marca
  como descadastrado e adiciona o e-mail original à supressão da empresa.
  Mantém a linha do contato (anonimizada) para integridade de relatórios.
  """
  @spec anonimizar_contato(Contact.t()) :: {:ok, Contact.t()} | {:error, term()}
  def anonimizar_contato(%Contact{} = contact) do
    email_original = contact.email
    anon_email = "anon-#{contact.id}@anonimizado.invalid"

    result =
      contact
      |> Ecto.Changeset.change(%{
        email: anon_email,
        first_name: nil,
        last_name: nil,
        data: %{},
        status: :unsubscribed,
        legal_basis: nil,
        source: "anonymized"
      })
      |> Repo.update()

    case result do
      {:ok, anon} ->
        # Bloqueia o e-mail original para nunca mais ser contatado/reimportado.
        if is_binary(email_original) do
          Keila.Suppressions.suprimir(email_original,
            project_id: contact.project_id,
            reason: "manual",
            source: "lgpd_anonimizacao"
          )
        end

        {:ok, anon}

      error ->
        error
    end
  end

  @doc """
  Exporta os dados de um contato (acesso/portabilidade) como um mapa simples,
  incluindo o histórico de consentimento.
  """
  @spec exportar_contato(Contact.t()) :: map()
  def exportar_contato(%Contact{} = contact) do
    %{
      email: contact.email,
      first_name: contact.first_name,
      last_name: contact.last_name,
      status: contact.status,
      legal_basis: contact.legal_basis,
      source: contact.source,
      data: contact.data,
      inserted_at: contact.inserted_at,
      double_opt_in_at: contact.double_opt_in_at,
      consent_history:
        Keila.Consent.historico_por_contato(contact.id)
        |> Enum.map(fn log ->
          %{
            legal_basis: log.legal_basis,
            source: log.source,
            double_opt_in: log.double_opt_in,
            ip: log.ip,
            occurred_at: log.occurred_at
          }
        end)
    }
  end

  defp get_contact_by_email(project_id, email) do
    normalized = email |> String.trim() |> String.downcase()

    Contact
    |> where([c], c.project_id == ^project_id and c.email == ^normalized)
    |> Repo.one()
  end

  defp stringify(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
