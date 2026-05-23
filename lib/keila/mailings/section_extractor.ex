defmodule Keila.Mailings.SectionExtractor do
  @moduledoc """
  Manipula `<mj-section>` blocos dentro do `<mj-body>` de um MJML.

  Permite listar, reordenar e remover seções inteiras sem reescrever o
  resto do MJML (head, attributes, styles). Usado pelo Modo Simples
  pra dar ao usuário controle macro da estrutura do email.

  Estratégia: regex em vez de parser XML completo. Funciona porque
  MJML é well-formed e as seções são top-level dentro de mj-body —
  sem aninhamento de mj-section dentro de mj-section.
  """

  @section_regex ~r/<mj-section\b[^>]*>.*?<\/mj-section>/s
  @body_regex ~r/(<mj-body\b[^>]*>)(.*)(<\/mj-body>)/s

  @doc """
  Lista as seções `<mj-section>` encontradas em ordem de aparição.

  Retorna `[%{index: 0, snippet: "...", preview: "..."}, ...]`.
  - `snippet`: o HTML completo da seção (pra reinserção)
  - `preview`: primeiros 60 chars do conteúdo textual (pra exibir na UI)
  """
  @spec list_sections(String.t()) :: [map()]
  def list_sections(mjml) when is_binary(mjml) do
    Regex.scan(@section_regex, mjml)
    |> Enum.with_index()
    |> Enum.map(fn {[snippet], idx} ->
      %{index: idx, snippet: snippet, preview: build_preview(snippet)}
    end)
  end

  def list_sections(_), do: []

  @doc """
  Move uma seção pra cima (idx-1). Retorna MJML novo (sem mudar se idx=0).
  """
  @spec move_up(String.t(), non_neg_integer()) :: String.t()
  def move_up(mjml, idx) when idx > 0, do: swap(mjml, idx, idx - 1)
  def move_up(mjml, _), do: mjml

  @doc """
  Move uma seção pra baixo (idx+1). Retorna MJML novo (sem mudar se já é a última).
  """
  @spec move_down(String.t(), non_neg_integer()) :: String.t()
  def move_down(mjml, idx) do
    sections = collect_sections(mjml)

    if idx < length(sections) - 1 do
      swap(mjml, idx, idx + 1)
    else
      mjml
    end
  end

  @doc """
  Remove uma seção pelo índice.
  """
  @spec remove(String.t(), non_neg_integer()) :: String.t()
  def remove(mjml, idx) do
    sections = collect_sections(mjml)

    if idx >= 0 and idx < length(sections) do
      new_sections = List.delete_at(sections, idx)
      replace_body_sections(mjml, new_sections)
    else
      mjml
    end
  end

  # ── internals ──

  defp swap(mjml, i, j) do
    sections = collect_sections(mjml)
    a = Enum.at(sections, i)
    b = Enum.at(sections, j)

    new_sections =
      sections
      |> List.replace_at(i, b)
      |> List.replace_at(j, a)

    replace_body_sections(mjml, new_sections)
  end

  defp collect_sections(mjml) do
    Regex.scan(@section_regex, mjml) |> Enum.map(fn [s] -> s end)
  end

  # Substitui o conteúdo entre <mj-body>...</mj-body> mantendo tudo entre
  # as seções (mj-raw, mj-include, comentarios) preservado se possível.
  # Estratégia: pega o texto entre seções, distribui no novo array.
  defp replace_body_sections(mjml, new_sections) do
    case Regex.run(@body_regex, mjml, capture: :all_but_first) do
      [open, body_inner, close] ->
        new_body = rebuild_body(body_inner, new_sections)
        # Substitui só a porção do body
        Regex.replace(@body_regex, mjml, fn _, _, _, _ -> open <> new_body <> close end)

      _ ->
        # Sem <mj-body> claro: só junta as seções
        Enum.join(new_sections, "\n")
    end
  end

  # Pega o "esqueleto" do body (tudo entre seções, em ordem) e injeta as
  # seções novas. Se o número de seções mudou (remoção), mantém o
  # delimitador inicial e final apenas.
  defp rebuild_body(body_inner, new_sections) do
    # Quebra o body original em "fillers" (entre seções)
    parts = Regex.split(@section_regex, body_inner, include_captures: false)

    # parts tem N+1 entries pra N seções originais. Quando #seções muda
    # (depois de remove), só mantemos primeiro e último filler.
    head = List.first(parts) || ""
    tail = List.last(parts) || ""

    cond do
      new_sections == [] ->
        head <> tail

      length(parts) == length(new_sections) + 1 ->
        # Mesma quantidade de seções: alterna parts e sections
        Enum.zip([Enum.drop(parts, -1), new_sections])
        |> Enum.map(fn {p, s} -> p <> s end)
        |> Enum.join("")
        |> Kernel.<>(tail)

      true ->
        # Quantidade mudou: só junta com newlines
        head <> Enum.join(new_sections, "\n  ") <> tail
    end
  end

  defp build_preview(snippet) do
    snippet
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.slice(0, 60)
  end
end
