defmodule Keila.Nps.Email do
  @moduledoc """
  Monta o e-mail de uma pesquisa de NPS para um envio específico.

  O e-mail é simples e em texto+HTML, com um único call-to-action: o link
  público `/nps/:token`. A nota é escolhida na página, não no e-mail, pra
  manter o disparo leve e a resposta sempre rastreável pelo token.
  """
  import Swoosh.Email

  alias Keila.Nps.{Pesquisa, Envio}

  @doc """
  Constrói o `Swoosh.Email` de um envio.

  `nome_empresa` aparece na assinatura; `to_email`/`to_name` vêm do contato.
  """
  def build(%Pesquisa{} = pesquisa, %Envio{} = envio, opts) do
    to_email = Keyword.fetch!(opts, :to_email)
    to_name = Keyword.get(opts, :to_name)
    nome_empresa = Keyword.get(opts, :nome_empresa, "nossa empresa")
    url = link(envio.token)
    primeiro_nome = primeiro_nome(to_name)

    new()
    |> to(if(to_name, do: {to_name, to_email}, else: to_email))
    |> subject("Sua opinião vale muito pra #{nome_empresa} 💜")
    |> text_body(texto(pesquisa, primeiro_nome, nome_empresa, url))
    |> html_body(html(pesquisa, primeiro_nome, nome_empresa, url))
  end

  @doc "URL pública de resposta de um token."
  def link(token) do
    "#{base_url()}/nps/#{token}"
  end

  defp texto(pesquisa, nome, empresa, url) do
    """
    Olá#{if nome, do: ", " <> nome, else: ""}!

    #{pesquisa.pergunta}

    É rapidinho — leva menos de 1 minuto. Basta abrir o link abaixo e escolher
    uma nota de 0 a 10:

    #{url}

    Sua resposta ajuda a #{empresa} a melhorar de verdade.

    Obrigado!
    --
    #{empresa}
    """
  end

  defp html(pesquisa, nome, empresa, url) do
    saudacao = if nome, do: "Olá, #{nome}!", else: "Olá!"

    """
    <!DOCTYPE html>
    <html lang="pt-BR">
    <body style="margin:0;padding:0;background:#f4f4f7;font-family:Arial,Helvetica,sans-serif;">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f7;padding:32px 0;">
        <tr><td align="center">
          <table role="presentation" width="520" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,0.08);">
            <tr><td style="background:linear-gradient(135deg,#6d28d9,#db2777);padding:28px 32px;">
              <p style="margin:0;color:#ffffff;font-size:20px;font-weight:bold;">#{empresa}</p>
            </td></tr>
            <tr><td style="padding:32px;">
              <p style="margin:0 0 12px;font-size:18px;font-weight:bold;color:#111827;">#{saudacao}</p>
              <p style="margin:0 0 24px;font-size:15px;line-height:1.6;color:#374151;">#{pesquisa.pergunta}</p>
              <table role="presentation" cellpadding="0" cellspacing="0" style="margin:0 auto;">
                <tr><td style="border-radius:10px;background:#6d28d9;">
                  <a href="#{url}" style="display:inline-block;padding:14px 32px;color:#ffffff;font-size:16px;font-weight:bold;text-decoration:none;">Responder agora</a>
                </td></tr>
              </table>
              <p style="margin:24px 0 0;font-size:13px;line-height:1.5;color:#6b7280;text-align:center;">
                Leva menos de 1 minuto. Sua resposta ajuda a #{empresa} a melhorar.
              </p>
            </td></tr>
            <tr><td style="padding:16px 32px;background:#f9fafb;border-top:1px solid #f0f0f0;">
              <p style="margin:0;font-size:12px;color:#9ca3af;">Você recebeu este e-mail porque é cliente da #{empresa}.</p>
            </td></tr>
          </table>
        </td></tr>
      </table>
    </body>
    </html>
    """
  end

  defp primeiro_nome(nil), do: nil
  defp primeiro_nome(""), do: nil
  defp primeiro_nome(nome) when is_binary(nome), do: nome |> String.split() |> List.first()

  defp base_url do
    scheme = System.get_env("URL_SCHEMA") || "https"
    host = System.get_env("URL_HOST") || "emailmkt.fluxodigitaltech.com.br"
    "#{scheme}://#{host}"
  end
end
