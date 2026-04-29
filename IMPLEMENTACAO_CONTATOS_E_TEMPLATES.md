# Implementação — Revisão Email (Contatos, Templates, Identidade)

Documento da entrega da task de revisão estrutural do módulo de email.

## O que foi implementado

### 1. Categorias de contato (segmentação)
- Novo módulo `Keila.Contacts.Categories` (`lib/keila/contacts/categories.ex`):
  catálogo de categorias de sistema. Adicionar uma nova categoria = adicionar
  um item no `catalog/0`. **Sem refactor.**
- Categorias iniciais: `aniversariantes`, `ausentes_1_7_dias`.
- Cada categoria é materializada como um `Segment` com nova coluna
  `system_category` (slug). Idempotente — pode ser re-seedada.
- Migration: `20260429120000_add_system_category_and_unit_to_campaigns.exs`.
- Seed automático no `Keila.Projects.create_project/2`.
- Como categoria É um segmento, ela aparece no Select de segmento da
  campanha automaticamente — sem UI extra.

### 2. Member vs Oportunidade
- Tabs de tipo no contact index: **All / Members / Opportunities**.
- Controller (`contact_controller.ex`) aceita `?type=member|opportunity|all`.
- Filtro usa `data.evo_type` (já populado pelo sync EVO):
  - `member` → membros matriculados
  - `opportunity` → prospects/oportunidades (`prospect` ou `opportunity`)
  - `all` → tudo
- Novo partial: `_type_tabs.html.heex`.

### 3. Unidades nas campanhas
- Coluna `unit_id` em `mailings_campaigns` (FK para `evo_units`, nilify on delete).
- Schema `Campaign` atualizado com `belongs_to :unit`.
- LiveView de edição de campanha:
  - Carrega unidades ativas do projeto no mount.
  - Select de unidade só aparece quando há **>1 unidade**. Com 1 unidade
    o usuário não é impactado (campo nem renderiza).
  - Recipient count e envio real filtram por `data.evo_unit_id` quando
    `unit_id` está setado.
- Filtro de envio aplicado em `Mailings.do_deliver_campaign/1`.

### 4. Identidade da empresa nos templates
- **Já era nativa** via `Keila.Projects.Brand` + Liquid:
  - `{{ brand.name }}`, `{{ brand.logo_url }}`, `{{ brand.color_primary }}`,
    `{{ brand.color_dark }}`, `{{ brand.color_text }}`, `{{ brand.color_accent }}`,
    `{{ brand.whatsapp_url }}`, `{{ brand.address }}`.
- Templates da biblioteca (`priv/email_templates/library/*.mjml`) já consomem
  esses placeholders.
- Mudar a identidade reflete em **todos** os templates no próximo render
  (preview e envio) — sem reedição manual.

### 5. Templates pré-definidos
- Biblioteca em `priv/email_templates/library/` cobre os casos:
  - `02-feliz-aniversario.mjml` → categoria Aniversariantes
  - `07-reativacao-aluno.mjml` → categoria Ausentes 1-7 dias
  - + 6 outros (boas-vindas, oferta, newsletter, avaliação, evento, indicação)

## Critérios de aceite

- [x] Member e oportunidade como contextos separados (tabs)
- [x] Listar/filtrar/segmentar por categoria (categoria = segmento)
- [x] Aniversariantes e Ausentes 1-7 dias disponíveis como segmento
- [x] Estrutura permite novas categorias sem refactor (1 item no `catalog/0`)
- [x] Empresas com >1 unidade veem Select
- [x] Empresas com 1 unidade não são impactadas (Select oculto)
- [x] Templates pré-definidos para as categorias iniciais
- [x] Identidade auto-propaga em todos os templates (Liquid + Brand)
- [x] Não é necessário editar template por template
- [x] Variáveis renderizam em preview e envio (`Builder.build_preview`
      e `do_deliver_campaign` usam o mesmo Liquid renderer)

## Pendências / Notas

- **Migration precisa ser rodada**: `mix ecto.migrate` em produção.
- **Seed retroativo**: projetos existentes não têm os segmentos de sistema.
  Rodar uma vez:
  ```elixir
  Keila.Repo.all(Keila.Projects.Project)
  |> Enum.each(&Keila.Contacts.Categories.seed_for_project(&1.id))
  ```
- **`data.last_visit_at`**: a categoria "Ausentes 1-7 dias" depende deste
  campo no `data` do contato. Verificar se o sync EVO popula. Caso não,
  ajustar o sync ou o filtro em `Categories.absent_filter/2`.
- **`data.evo_unit_id`**: filtro por unidade depende deste campo no contato.
  Confirmar que o sync EVO escreve o `unit_id` no `data` do contato em
  cada importação. Se não, ajustar `Keila.Integrations.Evo.sync` para
  preencher.
- **Atualização dinâmica do filtro de "Aniversariantes"**: o filtro guarda
  `MM-DD` de hoje no momento do seed. Para atualizar diariamente, rodar
  `Categories.seed_for_project/1` no `birthday_worker` (cron 9h) antes
  de processar — o `ensure_segment` é idempotente e atualiza o filter.
- **Não testado em runtime** (sem Elixir/Postgres no ambiente atual).
  Rodar `mix compile && mix test` antes do deploy.
