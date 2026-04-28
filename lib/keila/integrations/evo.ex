defmodule Keila.Integrations.Evo do
  @moduledoc """
  Client for the EVO fitness platform API.
  Fetches prospects (leads) from EVO and supports importing them as contacts.
  """

  require Logger

  @prospects_url "https://evo-integracao-api.w12app.com.br/api/v1/prospects"
  @members_url "https://evo-integracao-api.w12app.com.br/api/v1/members"
  @page_size 50

  @doc """
  Faz fetch de MEMBERS (alunos matriculados) da EVO. Mesmo padrão de
  `fetch_prospects/1` mas no endpoint /members.

  Retorna `{:ok, members_list, total}` ou `{:error, reason}`.
  """
  @spec fetch_members(keyword()) :: {:ok, list(), integer()} | {:error, term()}
  def fetch_members(opts \\ []) do
    with {:ok, dns} <- get_config(:evo_dns, opts),
         {:ok, secret} <- get_config(:evo_secret_key, opts) do
      auth = Base.encode64("#{dns}:#{secret}")

      case fetch_all_members_pages(auth, 0, []) do
        {:ok, members} ->
          members_with_email =
            members
            |> Enum.filter(&has_valid_email?/1)
            |> Enum.map(&normalize_member/1)

          {:ok, members_with_email, length(members)}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp fetch_all_members_pages(auth, skip, acc) do
    url = "#{@members_url}?take=#{@page_size}&skip=#{skip}"
    headers = [{"Authorization", "Basic #{auth}"}]

    case HTTPoison.get(url, headers, recv_timeout: 15_000) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} when is_list(data) ->
            new_acc = acc ++ data

            if length(data) < @page_size do
              {:ok, new_acc}
            else
              fetch_all_members_pages(auth, skip + @page_size, new_acc)
            end

          {:ok, _other} ->
            {:ok, acc}

          {:error, _} ->
            {:error, "Resposta inválida do EVO (members)"}
        end

      {:ok, %{status_code: status, body: body}} ->
        Logger.error("[EVO Members] API status #{status}: #{body}")
        {:error, "EVO retornou status #{status}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "EVO request failed: #{inspect(reason)}"}
    end
  end

  defp normalize_member(member) do
    contract_status =
      case member["currentContract"] do
        %{"status" => s} -> s
        _ -> nil
      end

    %{
      name: member["name"] || member["firstName"] || "",
      first_name: member["firstName"] || extract_first_name(member["name"]),
      last_name: member["lastName"] || extract_last_name(member["name"]),
      email: String.trim(member["email"] || ""),
      phone: member["phone"] || member["cellphone"] || "",
      register_date: member["registerDate"] || "",
      branch: member["branchName"] || member["branch"] || "",
      id_evo: member["idMember"] || member["id"] || nil,
      member_status: member["memberStatus"] || member["status"] || "Ativo",
      contract_status: contract_status,
      type: "member"
    }
  end

  @doc """
  Fetches prospects from the EVO API for a given date range.
  Returns only prospects that have a valid email address.

  ## Options
  - `:register_date_start` - Start date (format: "YYYY-MM-DD"). Defaults to first day of current month.
  - `:register_date_end` - End date (format: "YYYY-MM-DD"). Defaults to last day of current month.
  - `:evo_dns` - EVO DNS identifier (per-project config).
  - `:evo_secret_key` - EVO secret key (per-project config).
  """
  def fetch_prospects(opts \\ []) do
    with {:ok, dns} <- get_config(:evo_dns, opts),
         {:ok, secret} <- get_config(:evo_secret_key, opts) do
      {start_date, end_date} = date_range(opts)
      auth = Base.encode64("#{dns}:#{secret}")

      case fetch_all_pages(start_date, end_date, auth) do
        {:ok, prospects} ->
          prospects_with_email =
            prospects
            |> Enum.filter(&has_valid_email?/1)
            |> Enum.map(&normalize_prospect/1)

          {:ok, prospects_with_email, length(prospects)}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Faz fetch de prospects de uma LISTA de unidades EVO em paralelo.

  Cada prospect retornado vem marcado com `:evo_unit_id` e `:evo_unit_name`
  pra rastrear de qual academia veio.

  ## Argumentos
  - `units` — lista de `%Keila.Integrations.Evo.Unit{}`
  - `opts` — mesmas opções de `fetch_prospects/1` (register_date_start, register_date_end)

  ## Retorno
  ```
  {:ok, %{
    prospects: [%{...}, ...],   # prospects normalizados de TODAS unidades
    per_unit: %{unit_id => {:ok, count} | {:error, reason}},
    total_fetched: integer,
    total_with_email: integer
  }}
  ```
  """
  @spec fetch_prospects_multi([Keila.Integrations.Evo.Unit.t()], keyword()) ::
          {:ok, map()}
  def fetch_prospects_multi(units, opts \\ []) when is_list(units) do
    # Roda em paralelo com timeout por unidade
    results =
      units
      |> Task.async_stream(
        fn unit ->
          unit_opts =
            Keyword.merge(opts,
              evo_dns: unit.evo_dns,
              evo_secret_key: unit.evo_secret_key
            )

          {unit, fetch_prospects(unit_opts)}
        end,
        max_concurrency: 5,
        timeout: 30_000,
        on_timeout: :kill_task
      )
      |> Enum.to_list()

    {all_prospects, per_unit, total_fetched} =
      Enum.reduce(results, {[], %{}, 0}, fn
        {:ok, {unit, {:ok, prospects, total}}}, {acc, status, sum} ->
          tagged =
            Enum.map(prospects, fn p ->
              p
              |> Map.put(:evo_unit_id, unit.id)
              |> Map.put(:evo_unit_name, unit.name)
            end)

          {acc ++ tagged, Map.put(status, unit.id, {:ok, length(tagged)}), sum + total}

        {:ok, {unit, {:error, reason}}}, {acc, status, sum} ->
          Logger.warning(
            "[EVO Multi] Unidade #{unit.name} (#{unit.id}) falhou: #{inspect(reason)}"
          )

          {acc, Map.put(status, unit.id, {:error, reason}), sum}

        {:exit, reason}, {acc, status, sum} ->
          Logger.error("[EVO Multi] Task crashed: #{inspect(reason)}")
          {acc, status, sum}
      end)

    {:ok,
     %{
       prospects: all_prospects,
       per_unit: per_unit,
       total_fetched: total_fetched,
       total_with_email: length(all_prospects)
     }}
  end

  defp fetch_all_pages(start_date, end_date, auth) do
    fetch_all_pages(start_date, end_date, auth, 0, [])
  end

  defp fetch_all_pages(start_date, end_date, auth, skip, acc) do
    url =
      "#{@prospects_url}?registerDateStart=#{start_date}&registerDateEnd=#{end_date}&take=#{@page_size}&skip=#{skip}"

    headers = [{"Authorization", "Basic #{auth}"}]

    case HTTPoison.get(url, headers, recv_timeout: 15_000) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} when is_list(data) ->
            new_acc = acc ++ data

            if length(data) < @page_size do
              {:ok, new_acc}
            else
              fetch_all_pages(start_date, end_date, auth, skip + @page_size, new_acc)
            end

          {:ok, _other} ->
            {:ok, acc}

          {:error, _} ->
            {:error, "Failed to parse EVO API response"}
        end

      {:ok, %{status_code: status, body: body}} ->
        Logger.error("[EVO Integration] API returned status #{status}: #{body}")
        {:error, "EVO API returned status #{status}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("[EVO Integration] Request failed: #{inspect(reason)}")
        {:error, "EVO API request failed: #{inspect(reason)}"}
    end
  end

  defp has_valid_email?(%{"email" => email}) when is_binary(email) do
    email = String.trim(email)
    email != "" and String.contains?(email, "@")
  end

  defp has_valid_email?(_), do: false

  defp normalize_prospect(prospect) do
    %{
      name: prospect["name"] || prospect["firstName"] || "",
      first_name: prospect["firstName"] || extract_first_name(prospect["name"]),
      last_name: prospect["lastName"] || extract_last_name(prospect["name"]),
      email: String.trim(prospect["email"] || ""),
      phone: prospect["phone"] || prospect["cellphone"] || "",
      register_date: prospect["registerDate"] || "",
      source: prospect["prospectSource"] || prospect["source"] || "",
      status: prospect["prospectStatus"] || prospect["status"] || "",
      branch: prospect["branchName"] || prospect["branch"] || "",
      id_evo: prospect["idProspect"] || prospect["id"] || nil
    }
  end

  defp extract_first_name(nil), do: ""

  defp extract_first_name(name) do
    name |> String.split(" ", parts: 2) |> List.first() || ""
  end

  defp extract_last_name(nil), do: ""

  defp extract_last_name(name) do
    case String.split(name, " ", parts: 2) do
      [_, last] -> last
      _ -> ""
    end
  end

  defp date_range(opts) do
    start_date = Keyword.get(opts, :register_date_start)
    end_date = Keyword.get(opts, :register_date_end)

    if start_date && end_date do
      {start_date, end_date}
    else
      today = Date.utc_today()
      first_day = %{today | day: 1}
      last_day = Date.end_of_month(today)
      {Date.to_iso8601(first_day), Date.to_iso8601(last_day)}
    end
  end

  defp get_config(:evo_dns, opts) do
    case Keyword.get(opts, :evo_dns) do
      nil ->
        case System.get_env("EVO_DNS") do
          nil -> {:error, "EVO_DNS not configured. Configure in project settings."}
          val -> {:ok, val}
        end

      val when is_binary(val) and val != "" ->
        {:ok, val}

      _ ->
        {:error, "EVO_DNS not configured. Configure in project settings."}
    end
  end

  defp get_config(:evo_secret_key, opts) do
    case Keyword.get(opts, :evo_secret_key) do
      nil ->
        case System.get_env("EVO_SECRET_KEY") do
          nil -> {:error, "EVO_SECRET_KEY not configured. Configure in project settings."}
          val -> {:ok, val}
        end

      val when is_binary(val) and val != "" ->
        {:ok, val}

      _ ->
        {:error, "EVO_SECRET_KEY not configured. Configure in project settings."}
    end
  end
end
