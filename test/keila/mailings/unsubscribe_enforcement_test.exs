defmodule Keila.Mailings.UnsubscribeEnforcementTest do
  use ExUnit.Case, async: true
  alias Keila.Mailings
  alias Keila.Mailings.Campaign
  alias Keila.Templates.Template

  describe "campaign_has_unsubscribe?/1 (regra inegociável nº 2)" do
    test "passa com placeholder Liquid no corpo (texto/html/mjml)" do
      assert Mailings.campaign_has_unsubscribe?(%Campaign{text_body: "Oi {{ unsubscribe_link }}"})
      assert Mailings.campaign_has_unsubscribe?(%Campaign{mjml_body: "use {{ link_unsubscribe }}"})

      assert Mailings.campaign_has_unsubscribe?(%Campaign{
               html_body: "<a href='x'>Descadastrar</a>"
             })
    end

    test "passa com link /unsubscribe/ explícito" do
      assert Mailings.campaign_has_unsubscribe?(%Campaign{
               html_body: "<a href='https://x/unsubscribe/p/r/h'>sair</a>"
             })
    end

    test "passa quando o descadastro está no template" do
      assert Mailings.campaign_has_unsubscribe?(%Campaign{
               text_body: "Promo",
               template: %Template{body: "rodapé {{ unsubscribe_link }}"}
             })
    end

    test "passa via json_body (editor de blocos)" do
      assert Mailings.campaign_has_unsubscribe?(%Campaign{
               json_body: %{"blocks" => [%{"text" => "Cancelar inscrição"}]}
             })
    end

    test "falha quando não há nenhum mecanismo de descadastro" do
      refute Mailings.campaign_has_unsubscribe?(%Campaign{
               text_body: "Compre agora!",
               html_body: "<p>Oferta imperdível</p>"
             })

      refute Mailings.campaign_has_unsubscribe?(%Campaign{})
    end
  end
end
