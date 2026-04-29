defmodule Keila.Integrations.Evo.Units do
  @moduledoc """
  Context para gerenciar unidades EVO de um projeto.

  Funções principais:
  - list_units/1 — todas unidades de um projeto
  - list_active_units/1 — só ativas (usadas pelo sync worker)
  - create_unit/1 — cadastrar nova unidade
  - update_unit/2 — editar
  - delete_unit/1 — remover
  - test_connection/1 — pingar EVO API com credenciais
  - mark_sync_success/1 / mark_sync_error/2 — atualiza status pós-sync
  """

  import Ecto.Query
  alias Keila.Repo
  alias Keila.Integrations.Evo
  alias Keila.Integrations.Evo.Unit

  @spec list_units(binary()) :: [Unit.t()]
  def list_units(project_id) do
    Unit
    |> where([u], u.project_id == ^project_id)
    |> order_by([u], asc: u.name)
    |> Repo.all()
  end

  @spec list_active_units(binary()) :: [Unit.t()]
  def list_active_units(project_id) do
    Unit
    |> where([u], u.project_id == ^project_id and u.active == true)
    |> order_by([u], asc: u.name)
    |> Repo.all()
  end

  @spec get_unit(binary()) :: Unit.t() | nil
  def get_unit(unit_id), do: Repo.get(Unit, unit_id)

  @spec create_unit(map()) :: {:ok, Unit.t()} | {:error, Ecto.Changeset.t()}
  def create_unit(params) do
    params
    |> Unit.creation_changeset()
    |> Repo.insert()
  end

  @spec update_unit(Unit.t(), map()) :: {:ok, Unit.t()} | {:error, Ecto.Changeset.t()}
  def update_unit(%Unit{} = unit, params) do
    unit
    |> Unit.update_changeset(params)
    |> Repo.update()
  end

  @spec delete_unit(Unit.t()) :: {:ok, Unit.t()} | {:error, Ecto.Changeset.t()}
  def delete_unit(%Unit{} = unit), do: Repo.delete(unit)

  @doc """
  Testa as credenciais de uma unidade chamando a API EVO.
  Retorna :ok se autenticou (mesmo que retorne 0 prospects), {:error, msg} caso contrário.
  """
  @spec test_connection(Unit.t()) :: :ok | {:error, String.t()}
  def test_connection(%Unit{} = unit) do
    today = Date.utc_today()
    # Janela de 7 dias só pra validar auth — não precisa trazer dados de verdade
    start_date = today |> Date.add(-7) |> Date.to_iso8601()
    end_date = Date.to_iso8601(today)

    case Evo.fetch_prospects(
           evo_dns: unit.evo_dns,
           evo_secret_key: unit.evo_secret_key,
           register_date_start: start_date,
           register_date_end: end_date
         ) do
      {:ok, _prospects, _total} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @spec mark_sync_success(Unit.t()) :: {:ok, Unit.t()} | {:error, Ecto.Changeset.t()}
  def mark_sync_success(%Unit{} = unit) do
    update_unit(unit, %{
      last_sync_at: DateTime.utc_now() |> DateTime.truncate(:second),
      last_sync_status: "ok",
      last_sync_error: nil
    })
  end

  @spec mark_sync_error(Unit.t(), String.t()) ::
          {:ok, Unit.t()} | {:error, Ecto.Changeset.t()}
  def mark_sync_error(%Unit{} = unit, reason) do
    update_unit(unit, %{
      last_sync_at: DateTime.utc_now() |> DateTime.truncate(:second),
      last_sync_status: "error",
      last_sync_error: reason
    })
  end
end
