defmodule KeilaWeb.BirthdaysView do
  use KeilaWeb, :view

  def format_birth_md(md) when is_binary(md) do
    case String.split(md, "-") do
      [m, d] -> "#{d}/#{m}"
      _ -> md
    end
  end

  def format_birth_md(_), do: "—"

  def days_until(iso) do
    today = Date.utc_today()

    case Date.from_iso8601(iso) do
      {:ok, date} ->
        diff = Date.diff(date, today)

        cond do
          diff == 0 -> "Hoje"
          diff == 1 -> "Amanhã"
          diff < 7 -> "Em #{diff} dias"
          true -> "Em #{diff} dias"
        end

      _ ->
        ""
    end
  end
end
