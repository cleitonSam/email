defmodule Keila.Templates.Blocks do
  @moduledoc """
  Biblioteca de blocos MJML reusaveis pra inserir dentro de uma campanha.

  Diferente de `Keila.Templates.Library` (templates completos), aqui sao
  *snippets* — pedacos de MJML (hero, header, CTA, footer, etc) que o
  usuario insere dentro de um `<mj-body>` ja existente.

  Os arquivos MJML ficam em `priv/email_blocks/<slug>.mjml`.
  """

  @blocks_dir "priv/email_blocks"

  @blocks [
    %{
      slug: "hero-text",
      title: "Hero com texto",
      category: "Hero",
      icon: "✨",
      description: "Título grande, subtítulo e botão de chamada."
    },
    %{
      slug: "hero-image",
      title: "Hero com imagem de fundo",
      category: "Hero",
      icon: "🖼️",
      description: "Banner com imagem de fundo escura e texto branco em cima."
    },
    %{
      slug: "header-logo",
      title: "Cabeçalho só com logo",
      category: "Cabeçalho",
      icon: "🏷️",
      description: "Logo centralizada, fundo branco. Mais limpo."
    },
    %{
      slug: "header-logo-menu",
      title: "Cabeçalho logo + menu",
      category: "Cabeçalho",
      icon: "🧭",
      description: "Logo à esquerda, links de navegação à direita."
    },
    %{
      slug: "cta-button",
      title: "Botão de chamada",
      category: "Botão",
      icon: "👉",
      description: "Um botão centralizado, estilo primário."
    },
    %{
      slug: "cta-double",
      title: "Dois botões lado a lado",
      category: "Botão",
      icon: "⚖️",
      description: "Botão primário + secundário (ex: 'Começar' e 'Saber mais')."
    },
    %{
      slug: "countdown",
      title: "Urgência / contagem",
      category: "Conversão",
      icon: "⏰",
      description: "Bloco com prazo grande e CTA. Para promoções."
    },
    %{
      slug: "text-block",
      title: "Bloco de texto",
      category: "Conteúdo",
      icon: "📝",
      description: "Subtítulo + parágrafo. O bloco mais usado."
    },
    %{
      slug: "feature-3cols",
      title: "3 benefícios em colunas",
      category: "Conteúdo",
      icon: "🧩",
      description: "Três colunas com ícone, título e descrição curta."
    },
    %{
      slug: "image-text-left",
      title: "Imagem + texto ao lado",
      category: "Conteúdo",
      icon: "🖼️",
      description: "Imagem à esquerda, texto à direita. Bom pra histórias."
    },
    %{
      slug: "quote",
      title: "Citação / depoimento",
      category: "Conteúdo",
      icon: "💬",
      description: "Frase em destaque com autor. Estilo testimonial."
    },
    %{
      slug: "divider",
      title: "Divisor",
      category: "Conteúdo",
      icon: "➖",
      description: "Linha fina pra separar seções."
    },
    %{
      slug: "product-card",
      title: "Card de produto",
      category: "Produto",
      icon: "🛍️",
      description: "Imagem + nome + descrição + preço + botão comprar."
    },
    %{
      slug: "price-table",
      title: "Tabela de preços (3 planos)",
      category: "Produto",
      icon: "💳",
      description: "Básico / Pro / Empresa. Plano do meio destacado."
    },
    %{
      slug: "social-icons",
      title: "Ícones de redes sociais",
      category: "Rodapé",
      icon: "📱",
      description: "Instagram, Facebook, LinkedIn, YouTube."
    },
    %{
      slug: "footer-simple",
      title: "Rodapé simples",
      category: "Rodapé",
      icon: "🏁",
      description: "Endereço + link de descadastro. Fundo escuro."
    },
    %{
      slug: "footer-complete",
      title: "Rodapé completo",
      category: "Rodapé",
      icon: "🏗️",
      description: "Logo + colunas (Empresa, Siga) + link de descadastro."
    }
  ]

  @doc """
  Lista todos os blocos disponiveis (apenas metadata, sem carregar o MJML).
  """
  @spec list_blocks() :: [map()]
  def list_blocks, do: @blocks

  @doc """
  Lista as categorias unicas, na ordem de aparicao.
  """
  @spec list_categories() :: [String.t()]
  def list_categories do
    @blocks
    |> Enum.map(& &1.category)
    |> Enum.uniq()
  end

  @doc """
  Carrega o snippet MJML de um bloco pelo slug.
  """
  @spec load_mjml(String.t()) :: {:ok, String.t()} | {:error, atom()}
  def load_mjml(slug) when is_binary(slug) do
    if Enum.any?(@blocks, &(&1.slug == slug)) do
      path = Path.join([Application.app_dir(:keila), @blocks_dir, "#{slug}.mjml"])

      case File.read(path) do
        {:ok, content} -> {:ok, content}
        {:error, _} -> {:error, :file_not_found}
      end
    else
      {:error, :not_found}
    end
  end
end
