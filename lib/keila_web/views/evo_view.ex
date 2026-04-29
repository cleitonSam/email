defmodule KeilaWeb.EvoView do
  use KeilaWeb, :view

  def meta("index.html", :title, _assigns), do: gettext("EVO Integration")
  def meta("evo_live.html", :title, _assigns), do: gettext("EVO Integration")
  def meta(_template, _key, _assigns), do: nil

  def filter_prospects(prospects, ""), do: prospects

  def filter_prospects(prospects, search) do
    search = String.downcase(search)

    Enum.filter(prospects, fn p ->
      String.contains?(String.downcase(p.name || ""), search) or
        String.contains?(String.downcase(p.email || ""), search) or
        String.contains?(String.downcase(p.phone || ""), search)
    end)
  end

  def format_date(nil), do: ""
  def format_date(""), do: ""

  def format_date(date_string) when is_binary(date_string) do
    case String.split(date_string, "T") do
      [date | _] ->
        case String.split(date, "-") do
          [y, m, d] -> "#{d}/#{m}/#{y}"
          _ -> date_string
        end

      _ ->
        date_string
    end
  end

  def format_date(_), do: ""
end
