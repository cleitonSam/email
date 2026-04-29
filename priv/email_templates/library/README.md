# Biblioteca de Templates — Fluxo Email MKT

Templates MJML prontos para uso, com personalização Liquid. Cada cliente (projeto) pode forkar um template, ajustar marca/cores/textos e vincular a uma cadência.

## Como funciona

1. **Master**: arquivos `.mjml` desta pasta. São os templates oficiais mantidos pela Fluxo Digital Tech.
2. **Cópia por projeto**: ao clicar "Usar modelo" no admin, criamos um registro em `templates` com `parent_template_id` apontando pra esta master.
3. **Edição**: cliente abre no editor visual, troca logo, cores, textos, imagens. Salva como "Boas-vindas Academia X".
4. **Vinculação**: no editor de automação, cada step da cadência aponta pra um template do projeto.
5. **Atualização**: quando publicarmos melhoria no master, o cliente vê um aviso "Atualizar a partir do modelo" e aplica via 3-way merge.

## Variáveis Liquid disponíveis

### Contato
- `{{ first_name }}` — primeiro nome (extraído do `name` do EVO)
- `{{ last_name }}` — sobrenome
- `{{ contact.email }}` — e-mail
- `{{ unidade }}` — `branchName` do EVO
- `{{ id_evo }}` — `idProspect` ou `idMember`
- `{{ register_date }}` — data de cadastro/matrícula

### Marca da empresa (do `project.brand_settings`)
- `{{ brand.logo_url }}` — URL do logo (aparece no header)
- `{{ brand.color_primary }}` — cor principal (CTA, links)
- `{{ brand.color_accent }}` — cor de destaque
- `{{ brand.color_dark }}` — cor para hero e textos fortes
- `{{ brand.font_heading }}` — fonte dos títulos
- `{{ brand.address }}` — endereço da unidade (footer)
- `{{ brand.cnpj }}` — CNPJ
- `{{ brand.whatsapp_url }}` — link direto para WhatsApp
- `{{ brand.instagram_url }}` — Instagram

### URLs da cadência
- `{{ link_agendamento }}` — URL para agendar visita/avaliação
- `{{ link_oferta }}` — URL com cupom/oferta
- `{{ link_evento }}` — URL para RSVP de evento
- `{{ link_unsubscribe }}` — descadastro one-click (preenchido pelo Keila)

### Específicas
- `{{ dias_restantes }}` — para D+15 do aniversário
- `{{ data_evento }}`, `{{ horario_evento }}`, `{{ local_evento }}`

## Catálogo

| # | Arquivo | Categoria | Quando usar |
|---|---------|-----------|-------------|
| 01 | `boas-vindas-matricula.mjml` | onboarding | D+1 da Oportunidade ou após primeira matrícula |
| 02 | `feliz-aniversario.mjml` | celebração | D0 da cadência Aniversariante |
| 03 | `oferta-limitada.mjml` | promo | D+5 da Oportunidade ou campanhas pontuais |
| 04 | `newsletter-mes.mjml` | engajamento | mensal, todos os ativos |
| 05 | `avaliacao-fisica.mjml` | conversão | D+3 da Oportunidade ou trimestral |
| 06 | `convite-evento.mjml` | evento | aulão, workshop, abertura |
| 07 | `reativacao-aluno.mjml` | win-back | inativos > 60 dias |
| 08 | `indicacao-amigo.mjml` | growth | member-get-member |

## Princípios de design

- **Hero forte** — primeira coisa que o usuário vê, ocupa espaço, tem peso visual.
- **CTA único** — um só botão dominante por e-mail. Sem distração.
- **Tipografia hierárquica** — headline 36-44px, subhead 18px, body 16px.
- **Cor com economia** — fundo branco/preto, brand color só no CTA e em 1-2 acentos.
- **Mobile-first** — tudo testado em 320px de largura.
- **Acessibilidade** — contraste AA, alt text em todas as imagens, links sublinhados.
- **Footer enxuto** — logo + endereço + descadastro + 2 redes. Não vira menu.
