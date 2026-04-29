defmodule Keila.Automations.Recipes do
  @moduledoc """
  Catálogo de "Receitas" prontas — automações pré-configuradas que o usuário
  ativa com 1 clique. Cada receita define o trigger (status do prospect EVO)
  e a sequência de passos (delay + template).

  As receitas são DEFINIDAS EM CÓDIGO (não no banco) pra garantir que o
  fluxo já vem testado. Quando o usuário ativa uma receita pra uma unidade,
  criamos `Automation` + `Steps` no banco baseados nessa definição.
  """

  @recipes [
    %{
      slug: "lead_novo",
      title: "Lead novo chegou",
      icon: "✨",
      description:
        "Quando um lead novo aparece na EVO, manda boas-vindas hoje, convite pra aula em 3 dias, e oferta em 7 dias.",
      trigger_status: "Lead novo",
      steps: [
        %{order: 1, delay_days: 0, template_slug: "01-boas-vindas-matricula"},
        %{order: 2, delay_days: 3, template_slug: "05-avaliacao-fisica"},
        %{order: 3, delay_days: 7, template_slug: "03-oferta-limitada"}
      ]
    },
    %{
      slug: "lead_negociacao",
      title: "Lead em negociação",
      icon: "🔥",
      description:
        "Quando o lead tá em negociação mas trava, manda lembrete em 2 dias e oferta especial em 5.",
      trigger_status: "Em negociação",
      steps: [
        %{order: 1, delay_days: 2, template_slug: "06-convite-evento"},
        %{order: 2, delay_days: 5, template_slug: "03-oferta-limitada"}
      ]
    },
    %{
      slug: "lead_perdido",
      title: "Lead perdido / reengajamento",
      icon: "💔",
      description:
        "Pra leads que esfriaram. Reengajamento depois de 30 dias com tom acolhedor — sem pressão.",
      trigger_status: "Perdido",
      steps: [
        %{order: 1, delay_days: 30, template_slug: "07-reativacao-aluno"}
      ]
    },
    %{
      slug: "matriculado",
      title: "Aluno se matriculou",
      icon: "🎉",
      description:
        "Quando o lead vira aluno, manda parabéns + dicas dos primeiros treinos. Bonus: aniversário 1 ano depois.",
      trigger_status: "Convertido",
      steps: [
        %{order: 1, delay_days: 0, template_slug: "01-boas-vindas-matricula"},
        %{order: 2, delay_days: 7, template_slug: "06-convite-evento"},
        %{order: 3, delay_days: 30, template_slug: "05-avaliacao-fisica"}
      ]
    },
    %{
      slug: "aniversariantes",
      title: "Aniversariantes do dia",
      icon: "🎂",
      description:
        "Todo dia às 9h, identifica quem faz aniversário hoje e manda mensagem afetiva com presente. Precisa de data de nascimento no contato (vem do EVO ou import de planilha).",
      trigger_status: "birthday",
      trigger_type: "daily_birthday",
      steps: [
        %{order: 1, delay_days: 0, template_slug: "02-feliz-aniversario"}
      ]
    }
  ]

  @spec list() :: [map()]
  def list, do: @recipes

  @spec get(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get(slug) do
    case Enum.find(@recipes, &(&1.slug == slug)) do
      nil -> {:error, :not_found}
      recipe -> {:ok, recipe}
    end
  end
end
