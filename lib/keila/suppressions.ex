defmodule Keila.Suppressions do
  @moduledoc """
  Lista de supressão (regra inegociável nº 3 + LGPD § 4 do Prompt Mestre).

  Trava dura que impede envio. Funciona por **e-mail** (sobrevive à recriação do
  contato) e em dois escopos:

    - por empresa (`project_id` preenchido)
    - global (`project_id == nil`) — bloqueio para todas as empresas

  O envio é barrado em `Keila.Mailings.Worker` via `suprimido?/2` antes de
  construir/enviar o e-mail.
  """
  import Ecto.Query

  alias Keila.Repo
  alias Keila.Suppressions.Suppression

  @doc """
  Suprime um e-mail. Idempotente: se já existir no mesmo escopo, retorna o
  registro existente em vez de erro de constraint.

  ## Exemplos
      Suppressions.suprimir("foo@bar.com", project_id: project_id, reason: "hard_bounce")
      Suppressions.suprimir("spam@bad.com", reason: "global_block", scope: :global)
  """
  @spec suprimir(String.t(), keyword()) :: {:ok, Suppression.t()} | {:error, Ecto.Changeset.t()}
  def suprimir(email, opts) do
    scope = Keyword.get(opts, :scope, :project)

    project_id =
      case scope do
        :global -> nil
        _ -> Keyword.get(opts, :project_id)
      end

    normalized = Suppression.normalize_email(email)

    # Idempotente sem ON CONFLICT (os índices únicos são parciais e não podem ser
    # inferidos por lista de colunas): busca antes; se não existe, insere; se a
    # corrida criar um duplicado, o unique_constraint do changeset captura e
    # rebuscamos.
    case get_existente(normalized, project_id) do
      %Suppression{} = existente ->
        {:ok, existente}

      nil ->
        params = %{
          email: normalized,
          project_id: project_id,
          reason: Keyword.get(opts, :reason, "manual"),
          source: Keyword.get(opts, :source),
          notes: Keyword.get(opts, :notes)
        }

        case params |> Suppression.changeset() |> Repo.insert() do
          {:ok, suppression} -> {:ok, suppression}
          {:error, _changeset} -> {:ok, get_existente(normalized, project_id)}
        end
    end
  end

  @doc """
  Indica se um e-mail está suprimido para um projeto — considerando tanto a
  supressão local quanto o bloqueio global.
  """
  @spec suprimido?(String.t(), term() | nil) :: boolean()
  def suprimido?(email, project_id) do
    normalized = Suppression.normalize_email(email)

    Suppression
    |> where([s], s.email == ^normalized)
    |> where([s], is_nil(s.project_id) or s.project_id == ^project_id)
    |> Repo.exists?()
  end

  @doc "Indica se um e-mail está no bloqueio global."
  @spec bloqueado_globalmente?(String.t()) :: boolean()
  def bloqueado_globalmente?(email) do
    normalized = Suppression.normalize_email(email)

    Suppression
    |> where([s], s.email == ^normalized and is_nil(s.project_id))
    |> Repo.exists?()
  end

  @doc "Remove uma supressão local de um e-mail (ex.: reinscrição consciente)."
  @spec remover(String.t(), term()) :: {integer(), nil}
  def remover(email, project_id) do
    normalized = Suppression.normalize_email(email)

    Suppression
    |> where([s], s.email == ^normalized and s.project_id == ^project_id)
    |> Repo.delete_all()
  end

  @doc "Lista supressões de um projeto (mais recentes primeiro)."
  @spec list_por_projeto(term(), keyword()) :: [Suppression.t()]
  def list_por_projeto(project_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 500)

    Suppression
    |> where([s], s.project_id == ^project_id)
    |> order_by([s], desc: s.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc "Conta supressões de um projeto."
  @spec contar_por_projeto(term()) :: integer()
  def contar_por_projeto(project_id) do
    Suppression
    |> where([s], s.project_id == ^project_id)
    |> Repo.aggregate(:count, :id)
  end

  defp get_existente(email, project_id) do
    normalized = Suppression.normalize_email(email)

    query =
      if is_nil(project_id) do
        Suppression |> where([s], s.email == ^normalized and is_nil(s.project_id))
      else
        Suppression |> where([s], s.email == ^normalized and s.project_id == ^project_id)
      end

    Repo.one(query)
  end
end
