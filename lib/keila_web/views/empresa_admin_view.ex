defmodule KeilaWeb.EmpresaAdminView do
  use KeilaWeb, :view

  def format_date(nil), do: "-"
  def format_date(datetime), do: Calendar.strftime(datetime, "%d/%m/%Y %H:%M")

  def formatar_cnpj(nil), do: "-"

  def formatar_cnpj(cnpj) when is_binary(cnpj) do
    digits = String.replace(cnpj, ~r/[^0-9]/, "")

    case digits do
      <<a::binary-2, b::binary-3, c::binary-3, d::binary-4, e::binary-2>> ->
        "#{a}.#{b}.#{c}/#{d}-#{e}"

      _ ->
        cnpj
    end
  end

  def status_label("ativa"), do: "Ativa"
  def status_label("convidada"), do: "Convite enviado"
  def status_label(other), do: other

  def status_classes("ativa"), do: "bg-emerald-500/15 text-emerald-300 border-emerald-500/20"
  def status_classes("convidada"), do: "bg-amber-500/15 text-amber-300 border-amber-500/20"
  def status_classes(_), do: "bg-gray-500/15 text-gray-300 border-gray-500/20"
end
