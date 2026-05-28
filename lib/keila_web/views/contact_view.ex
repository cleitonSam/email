defmodule KeilaWeb.ContactView do
  use KeilaWeb, :view
  use PhoenixHTMLHelpers

  # Traduz os atoms de erro do LiveView upload pra texto claro em pt-BR.
  # Usado na tela de importar contatos (CSV).
  def error_to_text(:too_large), do: "Arquivo muito grande (máximo 50MB)."
  def error_to_text(:not_accepted), do: "Tipo de arquivo não aceito. Use .csv, .txt ou .tsv."
  def error_to_text(:too_many_files), do: "Selecione só um arquivo por vez."
  def error_to_text(:external_client_failure), do: "Falha no upload — verifique sua conexão e tente de novo."
  def error_to_text(other), do: "Erro no upload: #{inspect(other)}"

  def table_sort_button(assigns) do
    assigns = assign(assigns, :active?, assigns[:current_key] == assigns[:key])

    ~H"""
    <button
      data-sort-key={@key}
      data-sort-order={if @active? and @current_order == 1, do: "-1", else: "1"}
      type="button"
      class={
        "w-6 px-1 rounded hover:bg-gray-600" <>
          ((@active? && " bg-gray-600 hover:bg-gray-700") || "")
      }
    >
      {if @active? and @current_order == -1,
        do: render_icon(:chevron_up),
        else: render_icon(:chevron_down)}
    </button>
    """
  end
end
