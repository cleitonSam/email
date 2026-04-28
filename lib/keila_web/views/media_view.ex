defmodule KeilaWeb.MediaView do
  use KeilaWeb, :view

  def format_upload_error(:too_large), do: "Arquivo muito grande (máx 10MB)"
  def format_upload_error(:not_accepted), do: "Tipo de arquivo não aceito"
  def format_upload_error(:too_many_files), do: "Muitos arquivos (máx 10 por vez)"
  def format_upload_error(other), do: "Erro: #{inspect(other)}"
end
