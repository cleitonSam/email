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
            # Debug: log estrutura do primeiro member pra ver campos disponíveis
            if skip == 0 and length(data) > 0 do
              first = List.first(data)
              keys = if is_map(first), do: Map.keys(first), else: []
              Logger.info("[EVO Members] Sample fields: #{inspect(Enum.take(keys, 30))}")

              if is_map(first) do
                birth_fields =
                  ["birthDate", "birthday", "dateOfBirth", "birth_date", "dataNascimento"]
                  |> Enum.filter(&Map.has_key?(first, &1))

                Logger.info("[EVO Members] Birth date fields detected: #{inspect(birth_fields)}")
              end
            end

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

    raw_birth =
      member["birthDate"] || member["birthday"] || member["dateOfBirth"] ||
        member["birth_date"] || member["dataNascimento"] || member["data_nascimento"] ||
        get_in(member, ["personalInfo", "birthDate"]) ||
        get_in(member, ["profile", "birthDate"]) ||
        nil

    %{
      name: member["name"] || member["firstName"] || "",
      first_name: member["firstName"] || extract_first_name(member["name"]),
      last_name: member["lastName"] || extract_last_name(member["name"]),
      email: String.trim(member["email"] || ""),
      phone: member["phone"] || member["cellphone"] || "",
      register_date: member["registerDate"] || "",
      birth_date: normalize_birth_date(raw_birth),
      birth_date_raw: raw_birth,
      branch: member["branchName"] || member["branch"] || "",
      id_evo: member["idMember"] || member["id"] || nil,
      member_status: member["memberStatus"] || member["status"] || "Ativo",
      contract_status: contract_status,
      type: "member"
    }
  end

  # Normaliza data de nascimento pra formato "MM-DD" (ano não importa pra aniversário).
  # Aceita: "1985-04-29T00:00:00", "1985-04-29", "29/04/1985"
  defp normalize_birth_date(nil), do: nil
  defp normalize_birth_date(""), do: nil

  defp normalize_birth_date(date_str) when is_binary(date_str) do
    cond do
      # ISO: 1985-04-29 ou 1985-04-29T00:00:00
      Regex.match?(~r/^\d{4}-\d{2}-\d{2}/, date_str) ->
        case String.split(date_str, "-") do
          [_year, month, day_part] ->
            day = String.slice(day_part, 0, 2)
            "#{month}-#{day}"

          _ ->
            nil
        end

      # BR: 29/04/1985
      Regex.match?(~r/^\d{2}\/\d{2}\/\d{4}/, date_str) ->
        [day, month, _] = String.split(date_str, "/")
        "#{month}-#{day}"

      true ->
        nil
    end
  end

  defp normalize_birth_date(_), do: nil

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
            Enum.map(prospects, fn p -