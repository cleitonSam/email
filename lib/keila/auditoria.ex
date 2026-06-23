defmodule Keila.Auditoria do
  @moduledoc """
  Trilha de auditoria (regra inegociável nº 8 do Prompt Mestre).

  Toda ação crítica deve passar por aqui: login, impersonation (modo suporte),
  import/export de contatos, mudança de permissão, cadastro/aprovação/bloqueio
  de empresa, disparo/bloqueio de campanha, etc.

  A gravação é deliberadamente "best-effort": um erro ao registrar a auditoria
  **nunca** deve derrubar a ação principal. Por isso `registrar/2` captura
  exceções e apenas loga, retornando `:ok`/`:error`.

  ## Uso

      Auditoria.registrar("empresa.kyb_aprovado",
        actor: current_user,
        entity: empresa,
        project_id: empresa.project_id,
        metadata: %{plano: "pro"}
      )

      # A partir de uma Plug.Conn (extrai IP e User-Agent automaticamente):
      Auditoria.registrar_conn(conn, "user.impersonate", entity: alvo)
  """
  import Ecto.Query
  require Logger

  alias Keila.Repo
  alias Keila.Auditoria.Log

  @type opts :: [
          actor: term(),
          actor_email: String.t() | nil,
          entity: term(),
          entity_type: String.t() | nil,
          entity_id: term() | nil,
          project_id: term() | nil,
          ip: String.t() | nil,
          user_agent: String.t() | nil,
          metadata: map()
        ]

  @doc """
  Registra uma ação de auditoria. Best-effort: nunca levanta exceção.
  """
  @spec registrar(String.t(), opts()) :: {:ok, Log.t()} | :error
  def registrar(action, opts \\ []) when is_binary(action) do
    params = build_params(action, opts)

    try do
      case params |> Log.changeset() |> Repo.insert() do
        {:ok, log} ->
          {:ok, log}

        {:error, changeset} ->
          Logger.error("[Auditoria] Falha ao registrar #{action}: #{inspect(changeset.errors)}")
          :error
      end
    rescue
      e ->
        Logger.error("[Auditoria] Exceção ao registrar #{action}: #{inspect(e)}")
        :error
    end
  end

  @doc """
  Registra uma ação extraindo IP e User-Agent de uma `Plug.Conn`, e usando o
  `current_user`/`current_account` já presentes nas assigns como ator e projeto.
  """
  @spec registrar_conn(Plug.Conn.t(), String.t(), opts()) :: {:ok, Log.t()} | :error
  def registrar_conn(%Plug.Conn{} = conn, action, opts \\ []) do
    actor = opts[:actor] || conn.assigns[:current_user]

    opts =
      opts
      |> Keyword.put_new(:actor, actor)
      |> Keyword.put_new(:ip, client_ip(conn))
      |> Keyword.put_new(:user_agent, user_agent(conn))

    registrar(action, opts)
  end

  @doc "Lista registros de auditoria de um projeto (mais recentes primeiro)."
  @spec list_por_projeto(term(), keyword()) :: [Log.t()]
  def list_por_projeto(project_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    Log
    |> where([l], l.project_id == ^project_id)
    |> order_by([l], desc: l.inserted_at)
    |> limit(^limit)
    |> preload(:actor_user)
    |> Repo.all()
  end

  @doc "Lista os registros mais recentes (visão global do Master Admin)."
  @spec list_recentes(keyword()) :: [Log.t()]
  def list_recentes(opts \\ []) do
    limit = Keyword.get(opts, :limit, 200)

    Log
    |> order_by([l], desc: l.inserted_at)
    |> limit(^limit)
    |> preload([:actor_user, :project])
    |> Repo.all()
  end

  # --- helpers internos ---

  defp build_params(action, opts) do
    {actor_id, actor_email} = actor_fields(opts)
    {entity_type, entity_id} = entity_fields(opts)

    %{
      action: action,
      actor_user_id: actor_id,
      actor_email: opts[:actor_email] || actor_email,
      entity_type: opts[:entity_type] || entity_type,
      entity_id: to_string_id(opts[:entity_id] || entity_id),
      project_id: opts[:project_id],
      ip: opts[:ip],
      user_agent: truncate(opts[:user_agent], 500),
      metadata: opts[:metadata] || %{}
    }
  end

  defp actor_fields(opts) do
    case opts[:actor] do
      %{id: id, email: email} -> {id, email}
      %{id: id} -> {id, nil}
      id when is_integer(id) -> {id, nil}
      id when is_binary(id) -> {id, nil}
      _ -> {nil, nil}
    end
  end

  defp entity_fields(opts) do
    case opts[:entity] do
      %module{id: id} -> {entity_type_from_module(module), id}
      _ -> {nil, nil}
    end
  end

  defp entity_type_from_module(module) do
    module |> Module.split() |> List.last() |> Macro.underscore()
  end

  defp to_string_id(nil), do: nil
  defp to_string_id(id), do: to_string(id)

  defp truncate(nil, _), do: nil
  defp truncate(str, max) when is_binary(str), do: String.slice(str, 0, max)
  defp truncate(other, _), do: other

  defp client_ip(%Plug.Conn{} = conn) do
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [value | _] -> value |> String.split(",") |> List.first() |> String.trim()
      _ -> conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  rescue
    _ -> nil
  end

  defp user_agent(%Plug.Conn{} = conn) do
    case Plug.Conn.get_req_header(conn, "user-agent") do
      [ua | _] -> ua
      _ -> nil
    end
  end
end
