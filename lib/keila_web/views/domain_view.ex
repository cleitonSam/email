defmodule KeilaWeb.DomainView do
  use KeilaWeb, :view

  def meta("index.html", :title, _assigns), do: gettext("Domínios de envio")
  def meta(_template, _key, _assigns), do: nil

  def format_date(nil), do: "—"
  def format_date(datetime), do: Calendar.strftime(datetime, "%d/%m/%Y %H:%M")

  def status_label("verified"), do: "Verificado"
  def status_label("failed"), do: "Falhou"
  def status_label("pending"), do: "Pendente"
  def status_label(other), do: other

  def status_classes("verified"), do: "bg-emerald-500/15 text-emerald-300 border-emerald-500/20"
  def status_classes("failed"), do: "bg-red-500/15 text-red-300 border-red-500/20"
  def status_classes(_), do: "bg-amber-500/15 text-amber-300 border-amber-500/20"

  def check_icon(true), do: "✓"
  def check_icon(false), do: "✗"
  def check_icon(_), do: "—"

  def check_classes(true), do: "text-emerald-400"
  def check_classes(false), do: "text-red-400"
  def check_classes(_), do: "text-gray-500"
end
