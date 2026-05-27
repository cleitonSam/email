defmodule Keila.Mailings.Builder.MJML do
  @moduledoc """
  Builder for MJML emails.

  Quando o MJML não compila, o builder ainda assim devolve um `html_body`
  com um card de erro amigável (em vez de despejar o erro cru), pra que os
  visualizadores (preview do editor, galeria, preview por email) não fiquem
  "quebrados". O header `X-Keila-Invalid` continua presente, então o envio
  real para os contatos segue bloqueado.
  """
  use KeilaWeb.Gettext
  import Swoosh.Email

  @spec put_body(Swoosh.Email.t(), String.t(), map()) :: Swoosh.Email.t()
  def put_body(email, mjml_content, assigns \\ %{}) do
    with {:ok, rendered_mjml} <- render_mjml(mjml_content),
         {:ok, html_body} <- render_liquid(rendered_mjml, assigns) do
      html_body(email, html_body)
    else
      {:error, reason} ->
        email
        |> html_body(error_html(reason))
        |> text_body(reason)
        |> header("X-Keila-Invalid", reason)
    end
  end

  # Tenta compilar o MJML como está. Se falhar, faz um reparo conservador
  # (extrai um único documento <mjml>...</mjml>, removendo lixo antes/depois
  # e um eventual segundo documento concatenado) e tenta novamente.
  defp render_mjml(input) do
    case Mjml.to_html(input) do
      {:ok, output} ->
        {:ok, output}

      {:error, reason} ->
        repaired = sanitize_mjml(input)

        if repaired != input do
          case Mjml.to_html(repaired) do
            {:ok, output} -> {:ok, output}
            {:error, reason2} -> {:error, mjml_error(reason2)}
          end
        else
          {:error, mjml_error(reason)}
        end
    end
  end

  defp mjml_error(reason),
    do: gettext("Error compiling MJML: %{reason}", reason: to_string(reason))

  # Extrai o trecho de `<mjml` até o primeiro `</mjml>` (inclusive), descartando
  # qualquer conteúdo antes ou depois. Se não achar a estrutura, devolve o input.
  defp sanitize_mjml(input) do
    trimmed = String.trim(input)
    close_tag = "</mjml>"

    with {start, _} <- :binary.match(trimmed, "<mjml"),
         body <- binary_part(trimmed, start, byte_size(trimmed) - start),
         {close, _} <- :binary.match(body, close_tag) do
      binary_part(body, 0, close + byte_size(close_tag))
    else
      _ -> trimmed
    end
  end

  defp render_liquid(input, assigns) do
    case Keila.Mailings.Builder.LiquidRenderer.render_liquid(input, assigns) do
      {:ok, output} ->
        {:ok, output}

      {:error, reason} ->
        {:error, gettext("Error compiling Liquid: %{reason}", reason: reason)}
    end
  end

  # Card de erro renderizado no preview quando o email não compila.
  # HTML autossuficiente (vai dentro do iframe de preview).
  defp error_html(reason) do
    safe_reason =
      reason
      |> to_string()
      |> String.replace("&", "&amp;")
      |> String.replace("<", "&lt;")
      |> String.replace(">", "&gt;")

    """
    <!DOCTYPE html>
    <html lang="pt-BR">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <style>
        body { margin:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
               background:#f3f4f6; color:#111827; display:flex; align-items:center;
               justify-content:center; min-height:100vh; padding:24px; box-sizing:border-box; }
        .card { background:#fff; border:1px solid #e5e7eb; border-radius:16px; max-width:440px;
                width:100%; padding:32px; text-align:center; box-shadow:0 10px 30px rgba(0,0,0,.06); }
        .icon { width:56px; height:56px; border-radius:14px; background:#fef2f2; color:#ef4444;
                display:inline-flex; align-items:center; justify-content:center; margin-bottom:16px; }
        h1 { font-size:18px; margin:0 0 8px; color:#111827; }
        p { font-size:14px; line-height:1.5; color:#6b7280; margin:0 0 16px; }
        .reason { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size:12px;
                  text-align:left; background:#f9fafb; border:1px solid #e5e7eb; border-radius:8px;
                  padding:12px; color:#b91c1c; word-break:break-word; }
        .hint { font-size:13px; color:#374151; margin-top:16px; }
        .hint strong { color:#111827; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="icon">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <h1>Não foi possível renderizar este email</h1>
        <p>Tem um erro no código MJML. O preview volta sozinho assim que o erro for corrigido.</p>
        <div class="reason">#{safe_reason}</div>
        <p class="hint">Abra a aba <strong>"Código MJML"</strong> pra encontrar e corrigir o trecho com problema.</p>
      </div>
    </body>
    </html>
    """
  end
end
