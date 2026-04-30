defmodule Keila.Integrations.Evo do
  @moduledoc "Client for the EVO fitness platform API."

  require Logger

  @prospects_url "https://evo-integracao-api.w12app.com.br/api/v1/prospects"
  @members_excel_url "https://evo-integracao.w12app.com.br/api/v1/members/summary-excel"
  @page_size 50

  @doc "Faz fetch de MEMBERS via summary-excel (XLSX)."
  @spec fetch_members(keyword()) :: {:ok, list(), integer()} | {:error, term()}
  def fetch_members(opts \\ []) do
    with {:ok, dns} <- get_config(:evo_dns, opts),
         {:ok, secret} <- get_config(:evo_secret_key, opts) do
      auth = Base.encode64("#{dns}:#{secret}")
      headers = [{"Authorization", "Basic #{auth}"}]
      Logger.info("[EVO Members] Fetching XLSX from #{@members_excel_url}")

      case HTTPoison.get(@members_excel_url, headers, recv_timeout: 60_000, timeout: 60_000) do
        {:ok, %{status_code: 200, body: body}} ->
          case parse_members_xlsx(body) do
            {:ok, rows} ->
              members = rows |> Enum.filter(&has_valid_email_row?/1) |> Enum.map(&normalize_member_row/1)
              with_birth = Enum.count(members, & &1.birth_date)
              Logger.info("[EVO Members] Parsed #{length(rows)} rows, #{length(members)} valid, #{with_birth} with birth_date")
              {:ok, members, length(rows)}

            {:error, reason} ->
              Logger.error("[EVO Members] XLSX parse failed: #{inspect(reason)}")
              {:error, "Falha ao processar planilha: #{inspect(reason)}"}
          end

        {:ok, %{status_code: status, body: body}} ->
          snippet = body |> to_string() |> String.slice(0, 300)
          Logger.error("[EVO Members] HTTP #{status}: #{snippet}")
          {:error, "EVO retornou status #{status}"}

        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("[EVO Members] Request failed: #{inspect(reason)}")
          {:error, "Falha de conexão: #{inspect(reason)}"}
      end
    end
  end

  defp parse_members_xlsx(binary) do
    with {:ok, package} <- XlsxReader.open(binary, source: :binary),
         [first_sheet | _] <- XlsxReader.sheet_names(package),
         {:ok, [headers | rows]} <- XlsxReader.sheet(package, first_sheet) do
      header_keys = Enum.map(headers, &normalize_header/1)
      data = Enum.map(rows, fn row -> Enum.zip(header_keys, row) |> Map.new() end)

      if length(data) > 0 do
        first = List.first(data)
        sample_keys = Map.keys(first)
        Logger.info("[EVO Members] XLSX raw headers: #{inspect(headers)}")
        Logger.info("[EVO Members] XLSX normalized columns: #{inspect(sample_keys)}")
        Logger.info("[EVO Members] First row sample: #{inspect(first |> Enum.take(20))}")
        birth_candidates = sample_keys |> Enum.filter(&(String.contains?(to_string(&1), "nasc") or String.contains?(to_string(&1), "birth") or String.contains?(to_string(&1), "data")))
        Logger.info("[EVO Members] Possible birth columns: #{inspect(birth_candidates)}")
      end

      {:ok, data}
    else
      {:error, reason} -> {:error, reason}
      [] -> {:error, "XLSX sem planilhas"}
      other -> {:error, "Inesperado: #{inspect(other)}"}
    end
  end

  defp normalize_header(h) when is_binary(h) do
    h |> String.trim() |> String.downcase() |> String.replace(~r/[^\w]+/u, "_") |> String.trim("_")
  end

  defp normalize_header(_), do: ""

  defp has_valid_email_row?(row) do
    email = get_row_field(row, ["email", "e_mail", "endereco_de_e_mail"])
    is_binary(email) and String.contains?(email, "@")
  end

  defp normalize_member_row(row) do
    name = get_row_field(row, ["nome", "name", "nome_completo"]) || ""
    email = get_row_field(row, ["email", "e_mail", "endereco_de_e_mail"]) |> trim_str()
    phone = get_row_field(row, ["telefone", "celular", "phone", "cellphone"]) |> trim_str()
    branch = get_row_field(row, ["filial", "branch", "branchname", "unidade"]) |> trim_str()
    raw_birth = find_birth_column(row)
    register_date = get_row_field(row, ["data_de_cadastro", "registerdate", "data_cadastro", "dt_cadastro"]) |> to_str()
    member_status = get_row_field(row, ["status", "memberstatus", "situacao"]) |> to_str()
    id_evo = get_row_field(row, ["id", "idmember", "codigo", "id_member", "matricula"]) |> to_str()

    %{
      name: name,
      first_name: extract_first_name(name),
      last_name: extract_last_name(name),
      email: email,
      phone: phone,
      register_date: register_date,
      birth_date: normalize_birth_date(raw_birth),
      birth_date_raw: to_str(raw_birth),
      branch: branch,
      id_evo: id_evo,
      member_status: member_status,
      contract_status: nil,
      type: "member"
    }
  end

  defp get_row_field(row, candidates) do
    Enum.find_value(candidates, fn key ->
      case Map.get(row, key) do
        nil -> nil
        "" -> nil
        v -> v
      end
    end)
  end

  # Acha QUALQUER coluna cujo nome contenha "nasc" ou "birth"
  defp find_birth_column(row) do
    Enum.find_value(row, fn {key, value} ->
      key_str = to_string(key)
      cond do
        value in [nil, ""] -> nil
        String.contains?(key_str, "nasc") -> value
        String.contains?(key_str, "birth") -> value
        true -> nil
      end
    end)
  end

  defp trim_str(v) when is_binary(v), do: String.trim(v)
  defp trim_str(nil), do: ""
  defp trim_str(v), do: to_string(v)

  defp to_str(nil), do: ""
  defp to_str(v) when is_binary(v), do: v
  defp to_str(%Date{} = d), do: Date.to_iso8601(d)
  defp to_str(%NaiveDateTime{} = dt), do: NaiveDateTime.to_iso8601(dt)
  defp to_str(v), do: to_string(v)

  defp normalize_birth_date(nil), do: nil
  defp normalize_birth_date(""), do: nil
  defp normalize_birth_date(%Date{month: m, day: d}), do: "#{pad(m)}-#{pad(d)}"
  defp normalize_birth_date(%NaiveDateTime{month: m, day: d}), do: "#{pad(m)}-#{pad(d)}"

  defp normalize_birth_date(date_str) when is_binary(date_str) do
    cond do
      Regex.match?(~r/^\d{4}-\d{2}-\d{2}/, date_str) ->
        case String.split(date_str, "-") do
          [_y, m, d] -> "#{m}-#{String.slice(d, 0, 2)}"
          _ -> nil
        end

      Regex.match?(~r/^\d{2}\/\d{2}\/\d{4}/, date_str) ->
        [d, m, _] = String.split(date_str, "/")
        "#{m}-#{d}"

      true ->
        nil
    end
  end

  defp normalize_birth_date(_), do: nil

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"

  @doc "Fetches prospects from EVO API."
  def fetch_prospects(opts \\ []) do
    with {:ok, dns} <- get_config(:evo_dns, opts),
         {:ok, secret} <- get_config(:evo_secret_key, opts) do
      {start_date, end_date} = date_range(opts)
      auth = Base.encode64("#{dns}:#{secret}")

      case fetch_all_pages(start_date, end_date, auth) do
        {:ok, prospects} ->
          prospects_with_email = prospects |> Enum.filter(&has_valid_email?/1) |> Enum.map(&normalize_prospect/1)
          {:ok, prospects_with_email, length(prospects)}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @spec fetch_prospects_multi([Keila.Integrations.Evo.Unit.t()], keyword()) :: {:ok, map()}
  def fetch_prospects_multi(units, opts \\ []) when is_list(units) do
    results =
      units
      |> Task.async_stream(
        fn unit ->
          unit_opts = Keyword.merge(opts, evo_dns: unit.evo_dns, evo_secret_key: unit.evo_secret_key)
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
          tagged = Enum.map(prospects, fn p -> p |> Map.put(:evo_unit_id, unit.id) |> Map.put(:evo_unit_name, unit.name) end)
          {acc ++ tagged, Map.put(status, unit.id, {:ok, length(tagged)}), sum + total}

        {:ok, {unit, {:error, reason}}}, {acc, status, sum} ->
          Logger.warning("[EVO Multi] Unit #{unit.name} failed: #{inspect(reason)}")
          {acc, Map.put(status, unit.id, {:error, reason}), sum}

        {:exit, reason}, {acc, status, sum} ->
          Logger.error("[EVO Multi] Task crashed: #{inspect(reason)}")
          {acc, status, sum}
      end)

    {:ok, %{prospects: all_prospects, per_unit: per_unit, total_fetched: total_fetched, total_with_email: length(all_prospects)}}
  end

  defp fetch_all_pages(start_date, end_date, auth), do: fetch_all_pages(start_date, end_date, auth, 0, [])

  defp fetch_all_pages(start_date, end_date, auth, skip, acc) do
    url = "#{@prospects_url}?registerDateStart=#{start_date}&registerDateEnd=#{end_date}&take=#{@page_size}&skip=#{skip}"
    headers = [{"Authorization", "Basic #{auth}"}]

    case HTTPoison.get(url, headers, recv_timeout: 15_000) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} when is_list(data) ->
            new_acc = acc ++ data
            if length(data) < @page_size, do: {:ok, new_acc}, else: fetch_all_pages(start_date, end_date, auth, skip + @page_size, new_acc)

          {:ok, _} -> {:ok, acc}
          {:error, _} -> {:error, "Failed to parse EVO API response"}
        end

      {:ok, %{status_code: status, body: body}} ->
        Logger.error("[EVO] Status #{status}: #{body}")
        {:error, "EVO API status #{status}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "EVO request failed: #{inspect(reason)}"}
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
  defp extract_first_name(name) when is_binary(name), do: name |> String.trim() |> String.split(" ", parts: 2) |> List.first() || ""
  defp extract_first_name(_), do: ""

  defp extract_last_name(nil), do: ""
  defp extract_last_name(name) when is_binary(name) do
    case name |> String.trim() |> String.split(" ", parts: 2) do
      [_, last] -> last
      _ -> ""
    end
  end
  defp extract_last_name(_), do: ""

  defp date_range(opts) do
    start_date = Keyword.get(opts, :register_date_start)
    end_date = Keyword.get(opts, :register_date_end)

    if start_date && end_date do
      {start_date, end_date}
    else
      today = Date.utc_today()
      # Default: last 60 days until today
      start = Date.add(today, -60)
      {Date.to_iso8601(start), Date.to_iso8601(today)}
    end
  end

  defp get_config(:evo_dns, opts) do
    case Keyword.get(opts, :evo_dns) do
      nil -> case System.get_env("EVO_DNS") do
        nil -> {:error, "EVO_DNS not configured."}
        val -> {:ok, val}
      end
      val when is_binary(val) and val != "" -> {:ok, val}
      _ -> {:error, "EVO_DNS not configured."}
    end
  end

  defp get_config(:evo_secret_key, opts) do
    case Keyword.get(opts, :evo_secret_key) do
      nil -> case System.get_env("EVO_SECRET_KEY") do
        nil -> {:error, "EVO_SECRET_KEY not configured."}
        val -> {:ok, val}
      end
      val when is_binary(val) and val != "" -> {:ok, val}
      _ -> {:error, "EVO_SECRET_KEY not configured."}
    end
  end
end
