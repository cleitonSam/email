defmodule KeilaWeb.ProjectAdminView do
  use KeilaWeb, :view

  def format_date(nil), do: "-"

  def format_date(datetime) do
    Calendar.strftime(datetime, "%d/%m/%Y %H:%M")
  end

  def has_evo_config?(project) do
    data = project.data || %{}
    data["evo_dns"] != nil and data["evo_dns"] != "" and
      data["evo_secret_key"] != nil and data["evo_secret_key"] != ""
  end
end
