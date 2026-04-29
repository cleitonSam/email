defmodule KeilaWeb.WizardView do
  use KeilaWeb, :view

  def format_upload_error(:too_large), do: "Arquivo grande demais (máx 5MB)"
  def format_upload_error(:not_accepted), do: "Tipo não aceito (use PNG, JPG, WebP ou SVG)"
  def format_upload_error(:too_many_files), do: "Só 1 logo por vez"
  def format_upload_error(other), do: "Erro: #{inspect(other)}"
end
