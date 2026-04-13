defmodule Keila.Integrations.Evo do
  @moduledoc """
  Client for the EVO fitness platform API.
  Fetches prospects (leads) from EVO and supports importing them as contacts.
  """

  require Logger

  @prospects_url "https://evo-integracao-api.w12app.com.br/api/v1/prospects"
  @page_size 50

  @doc """
  Fetches prospects from the EVO API for a given date range.
  Returns only prospects that have a valid email address.

  ## Options
  - `:register_date_start` - Start date (format: "YYYY-MM-DD"). Defaults to first day of current month.
  - `:register_date_end` - End date (format: "YYYY-MM-DD"). Defaults to last day of current month.
  """
  def fetch_prospects(opts \\ []) do
    with {:ok, dns} <- get_config(:evo_dns),
         {:ok, secret} <- get_config(:evo_secret_key) do
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

  defp get_config(:evo_dns) do
    case System.get_env("EVO_DNS") do
      nil -> {:error, "EVO_DNS not configured"}
      val -> {:ok, val}
    end
  end

  defp get_config(:evo_secret_key) do
    case System.get_env("EVO_SECRET_KEY") do
      nil -> {:error, "EVO_SECRET_KEY not configured"}
      val -> {:ok, val}
    end
  end
end
