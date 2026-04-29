defmodule Keila.Mailings.SimpleEditor do
  @moduledoc """
  Parser e serializer para o "Modo Simples" do editor MJML.

  Extrai os campos editaveis (texto, botao, link, imagem) de um MJML e
  aplica edicoes de volta na string preservando atributos, layout e
  variaveis Liquid (`{{ ... }}`).

    * `parse/1` -> lista de %{id, type, label, value, ...}
    * `apply_edits/2` -> MJML atualizado
  """

  # Cap pra nao estourar memoria em MJML maluco
  @max_fields 200

  @type field_type :: :text | :button | :button_link | :image_src | :image_alt
  @type field :: %{
          id: String.t(),
          type: field_type(),
          label: String.t(),
          value: String.t(),
          start: non_neg_integer(),
          length: non_neg_integer()
        }

  # ─── API publica ─────────────────────────────────────────────

  @doc """
  Le um MJML e devolve a lista de campos editaveis ordenada pela posicao
  no documento. Apenas campos dentro de `<mj-body>` sao considerados —
  defaults em `<mj-head>` ficam de fora pra nao confundir o leigo.
  """
  @spec parse(String.t()) :: [field()]
  def parse(mjml) when is_binary(mjml) do
    body = body_range(mjml)

    raw =
      []
      |> collect_text_blocks(mjml, body)
      |> collect_button_blocks(mjml, body)
      |> collect_attr(mjml, body, ~r/<mj-button\b[^>]*?\bhref="([^"]*)"[^>]*>/s, :button_link)
      |> collect_attr(mjml, body, ~r/<mj-image\b[^>]*?\bsrc="([^"]*)"[^>]*\/?>/s, :image_src)
      |> collect_attr(mjml, body, ~r/<mj-image\b[^>]*?\balt="([^"]*)"[^>]*\/?>/s, :image_alt)

    raw
    |> Enum.sort_by(& &1.start)
    |> Enum.take(@max_fields)
    |> Enum.with_index()
    |> Enum.map(fn {f, idx} ->
      Map.merge(f, %{
        id: "f#{idx}",
        label: build_label(f, idx)
      })
    end)
  end

  @doc """
  Aplica um mapa de edits (%{"f0" => "novo valor", ...}) no MJML e
  devolve a string atualizada. Edits que nao correspondem a campos
  validos sao silenciosamente ignorados.
  """
  @spec apply_edits(String.t(), %{optional(String.t()) => String.t()}) :: String.t()
  def apply_edits(mjml, edits) when is_binary(mjml) and is_map(edits) do
    fields = parse(mjml)

    fields
    |> Enum.filter(&Map.has_key?(edits, &1.id))
    # Aplica de tras pra frente pra nao invalidar os offsets anteriores
    |> Enum.sort_by(& &1.start, :desc)
    |> Enum.reduce(mjml, fn f, acc ->
      new_raw = Map.fetch!(edits, f.id)
      new_value = sanitize(new_raw, f.type)
      splice(acc, f.start, f.length, new_value)
    end)
  end

  # ─── Deteccao do mj-body ─────────────────────────────────────

  defp body_range(mjml) do
    case Regex.run(~r/<mj-body\b[^>]*>/s, mjml, return: :index) do
      [{open_start, open_len}] ->
        body_start = open_start + open_len

        body_end =
          case :binary.match(mjml, "</mj-body>",
                 scope: {body_start, byte_size(mjml) - body_start}
               ) do
            {pos, _} -> pos
            :nomatch -> byte_size(mjml)
          end

        {body_start, body_end}

      _ ->
        {0, byte_size(mjml)}
    end
  end

  defp in_body?(start, {body_start, body_end}),
    do: start >= body_start and start < body_end

  # ─── Coletores ───────────────────────────────────────────────

  defp collect_text_blocks(acc, mjml, body) do
    # (?<!/) evita casar com a tag self-closing <mj-text ... /> em mj-attributes
    Regex.scan(~r/<mj-text\b[^>]*?(?<!\/)>(.*?)<\/mj-text>/s, mjml, return: :index)
    |> Enum.flat_map(fn
      [_full, {s, len}] when len > 0 ->
        if in_body?(s, body) do
          v = binary_part(mjml, s, len)

          # Pula textos so com emoji/ornamento (decorativos)
          if decorative_only?(v),
            do: [],
            else: [%{type: :text, start: s, length: len, value: v}]
        else
          []
        end

      _ ->
        []
    end)
    |> Kernel.++(acc)
  end

  defp collect_button_blocks(acc, mjml, body) do
    Regex.scan(~r/<mj-button\b[^>]*?(?<!\/)>(.*?)<\/mj-button>/s, mjml, return: :index)
    |> Enum.flat_map(fn
      [_full, {s, len}] when len > 0 ->
        if in_body?(s, body) do
          v = binary_part(mjml, s, len)
          [%{type: :button, start: s, length: len, value: v}]
        else
          []
        end

      _ ->
        []
    end)
    |> Kernel.++(acc)
  end

  defp collect_attr(acc, mjml, body, regex, type) do
    Regex.scan(regex, mjml, return: :index)
    |> Enum.flat_map(fn
      [_full, {s, len}] when len >= 0 ->
        if in_body?(s, body) do
          v = if len == 0, do: "", else: binary_part(mjml, s, len)
          [%{type: type, start: s, length: len, value: v}]
        else
          []
        end

      _ ->
        []
    end)
    |> Kernel.++(acc)
  end

  # ─── Splice / sanitizacao ────────────────────────────────────

  defp splice(string, start, length, replacement) do
    before = binary_part(string, 0, start)
    rest_offset = start + length
    rest = binary_part(string, rest_offset, byte_size(string) - rest_offset)
    before <> replacement <> rest
  end

  # Em atributos (URL, alt) nao pode ter aspas duplas ou < > soltos
  defp sanitize(value, type) when type in [:button_link, :image_src, :image_alt] do
    value
    |> String.replace(~r/["<>]/, "")
    |> String.trim()
  end

  defp sanitize(value, _), do: value

  # ─── Labels e heuristicas ────────────────────────────────────

  defp build_label(%{type: :text, value: v}, idx) do
    preview = preview_text(v)

    if heading_like?(v),
      do: "Titulo #{idx + 1}: #{preview}",
      else: "Texto #{idx + 1}: #{preview}"
  end

  defp build_label(%{type: :button, value: v}, idx),
    do: "Botao #{idx + 1} (texto): #{preview_text(v)}"

  defp build_label(%{type: :button_link, value: v}, idx) do
    short = if byte_size(v) > 40, do: binary_part(v, 0, 40) <> "…", else: v
    "Botao #{idx + 1} (link): #{short}"
  end

  defp build_label(%{type: :image_src}, idx), do: "Imagem #{idx + 1}"

  defp build_label(%{type: :image_alt, value: v}, idx) do
    short = if byte_size(v) > 40, do: binary_part(v, 0, 40) <> "…", else: v
    "Imagem #{idx + 1} (descricao alt): #{short}"
  end

  defp preview_text(v) do
    v
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> truncate(50)
  end

  defp truncate(s, max) when byte_size(s) > max,
    do: binary_part(s, 0, max) <> "…"

  defp truncate(s, _), do: s

  # Texto curto e ALL CAPS -> selo / etiqueta de secao
  defp heading_like?(v) do
    plain =
      v
      |> String.replace(~r/<[^>]+>/, " ")
      |> String.trim()

    byte_size(plain) > 0 and byte_size(plain) <= 60 and
      plain == String.upcase(plain) and plain =~ ~r/[A-ZÀ-Ý]/u
  end

  # Texto cujo conteudo visivel e so emoji/ornamento (✦, 🎂, etc.)
  defp decorative_only?(v) do
    plain =
      v
      |> String.replace(~r/<[^>]+>/, "")
      |> String.replace(~r/\s+/, "")

    cond do
      plain == "" -> true
      not (plain =~ ~r/\p{L}/u) -> true
      true -> false
    end
  end
end
