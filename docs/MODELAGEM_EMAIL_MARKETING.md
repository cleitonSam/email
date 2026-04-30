# Modelagem — Email Marketing (Contatos, Categorias, Unidades, Identidade)

Documento técnico das entidades envolvidas na revisão do módulo de email.
Cobre: schema, relacionamentos, fluxo de dados e pontos de extensão.

---

## 1. Visão geral das entidades

```
Account ──┐
          │
          ▼
       Project (tenant) ─── data.brand (Identidade)
          │
          ├── EvoUnit (1..N por projeto)
          │
          ├── Contact (1..N por projeto)
          │     └── data.evo_type    : "member" | "prospect" | "opportunity" | nil
          │     └── data.evo_unit_id : id da EvoUnit (popula no sync)
          │     └── data.birth_date  : "MM-DD"
          │     └── data.last_visit_at : ISO8601
          │
          ├── Segment (1..N por projeto)
          │     └── system_category  : slug | nil  (categorias de sistema)
          │     └── filter           : map MongoDB-like
          │
          ├── Sender
          ├── Template
          └── Campaign
                ├── segment_id  → Segment
                ├── unit_id     → EvoUnit (nullable)
                ├── sender_id   → Sender
                └── template_id → Template
```

---

## 2. Entidades

### 2.1 Contact (`Keila.Contacts.Contact`)

Tabela: `contacts`.

Campos relevantes para esta entrega:

| Campo | Tipo | Descrição |
|------|------|-----------|
| `id` | hashid (`c_*`) | PK |
| `project_id` | FK | tenancy |
| `email` | string | identificador funcional |
| `first_name`, `last_name` | string | |
| `status` | enum | `active`, `unsubscribed`, `unreachable` |
| `data` | map JSON | metadados estendidos (ver abaixo) |

**`data` (extensível)** — chaves usadas pelo sistema:

| Chave | Origem | Significado |
|-------|--------|-------------|
| `evo_type` | sync EVO | `member` (matriculado), `prospect`/`opportunity` (lead), ausente quando importado manualmente |
| `evo_id` | sync EVO | id externo no EVO |
| `evo_unit_id` | sync EVO | hashid da `EvoUnit` que originou o contato |
| `birth_date` | sync EVO | `MM-DD` (sem ano) |
| `last_visit_at` | sync EVO | ISO8601 da última visita registrada (membros) |

> **Member vs Oportunidade**: a distinção é via `data.evo_type`. Um member tem `birth_date` e `last_visit_at`; uma oportunidade só tem dados básicos. Tabs no UI filtram por essa chave.

### 2.2 EvoUnit (`Keila.Integrations.Evo.Unit`)

Tabela: `evo_units`. Representa uma academia/filial conectada ao EVO.

| Campo | Tipo | Notas |
|------|------|------|
| `id` | hashid (`eu_*`) | PK |
| `project_id` | FK | tenancy |
| `name` | string | nome exibido |
| `evo_dns`, `evo_secret_key` | string | credenciais EVO |
| `branch_label`, `cnpj`, `address`, `phone` | string | metadados |
| `is_primary` | bool | unidade principal |
| `active` | bool | se entra nos seletores |
| `last_sync_at`, `last_sync_status`, `last_sync_error` | | telemetria |

Relacionamentos: `belongs_to :project`. Contatos referenciam unidade via `data.evo_unit_id` (não FK forte — sobrevive a deleção de unidade).

### 2.3 Segment (`Keila.Contacts.Segment`)

Tabela: `contacts_segments`.

| Campo | Tipo | Notas |
|------|------|------|
| `id` | hashid (`sgm_*`) | PK |
| `project_id` | FK | tenancy |
| `name` | string | exibido no seletor |
| `filter` | map | filtro MongoDB-like aplicado em `Contacts.Query` |
| `system_category` | string\|nil | **novo** — slug da categoria de sistema |

**Index único parcial**: `(project_id, system_category) WHERE system_category IS NOT NULL` — garante 1 segmento por categoria por projeto.

### 2.4 Categoria de contato (`Keila.Contacts.Categories`)

**Não é uma tabela**. É um catálogo Elixir definido em código que se materializa
em `Segment.system_category`. Cada categoria tem:

```elixir
%{
  slug: "aniversariantes",        # único e estável
  name: "Aniversariantes",        # exibido no UI (igual ao Segment.name)
  filter: %{...}                  # gravado em Segment.filter
}
```

**Catálogo inicial** (`Categories.catalog/0`):
- `aniversariantes` — `{"data.birth_date" => "MM-DD de hoje"}`
- `ausentes_1_7_dias` — `data.last_visit_at` entre `hoje-7` e `hoje-1`

**Extensão**: adicionar nova categoria = 1 entrada no `catalog/0` + reseed.
Sem migração, sem refactor.

### 2.5 Identidade da empresa (Brand)

**Não é tabela separada**. É uma chave dentro de `projects.data["brand"]`,
encapsulada em `Keila.Projects.Brand`.

```elixir
%{
  "name" => "Academia Movimento",
  "logo_url" => "https://.../logo.png",
  "color_primary" => "#FF5A1F",
  "color_dark" => "#0A0E27",
  "color_text" => "#1A1A1A",
  "color_accent" => "#C4FF00",
  "whatsapp_url" => "https://wa.me/...",
  "address" => "Rua X, 123",
  "completed_at" => "2026-04-28T22:00:00Z"
}
```

`Brand.to_assigns(project)` produz `%{"brand" => brand_map}`, injetado no
contexto Liquid no momento do render.

### 2.6 Campaign (`Keila.Mailings.Campaign`)

Tabela: `mailings_campaigns`. Campos relevantes:

| Campo | Tipo | Notas |
|------|------|------|
| `segment_id` | FK Segment | público alvo (inclui categorias) |
| `unit_id` | FK EvoUnit (nullable) | **novo** — filtra por unidade quando setado |
| `sender_id`, `template_id` | FK | |
| `mjml_body`, `html_body`, `text_body`, `json_body` | | corpos |
| `subject`, `preview_text` | string | |
| `settings` | embed | tracking, etc. |

---

## 3. Fluxos

### 3.1 Disparo de campanha (filtro composto)

```elixir
filter = %{
  "$and" => [
    segment.filter,                                # do segment_id
    %{"data.evo_unit_id" => unit_id},             # se unit_id
    %{"status" => "active"}
  ]
}
```

Aplicado em:
- `Mailings.do_deliver_campaign/1` (envio real)
- `CampaignEditLive.put_recipient_count/1` (contagem de preview)

### 3.2 Render de template com identidade

1. Usuário cria template com placeholders Liquid: `{{ brand.color_primary }}` etc.
2. No preview (`Mailings.Builder.build_preview/1`) e no envio real, o renderer
   recebe assigns:
   ```
   %{
     "contact" => contact_struct,
     "campaign" => campaign_struct,
     "brand" => brand_map  # <- de Brand.to_assigns(project)
   }
   ```
3. Liquid substitui os placeholders no momento do render. **Mudar a identidade
   no project.data["brand"] reflete em TODOS os templates no próximo render**,
   sem reescrever corpos.

### 3.3 Seed de categorias (ciclo de vida)

```
create_project ─→ Categories.seed_for_project ─→ ensure_segment(catalog[0])
                                              └→ ensure_segment(catalog[1])
                                              └→ ...
```

`ensure_segment/2` é idempotente:
- Se não existe segmento com aquele `system_category`, cria.
- Se existe, atualiza `name` e `filter` para a versão mais recente do catálogo.

**Aniversariantes** depende da data corrente. Recomendação: chamar
`Categories.seed_for_project/1` no início do `BirthdayWorker` (cron diário 9h)
para que o filtro `MM-DD` esteja sempre atualizado.

---

## 4. Comportamento do Select de Unidade

| Cenário | Comportamento |
|--------|---------------|
| Projeto sem `evo_units` | Select **não renderiza**. `unit_id = nil`. Filtro ignora unidade. |
| Projeto com 1 unidade ativa | Select **não renderiza**. `unit_id = nil`. (Não há ambiguidade de público.) |
| Projeto com >1 unidade ativa | Select **renderiza** com opção "Todas as unidades" (default) + cada unidade. |

Decisão: para 1 unidade, o Select é **oculto** (não pré-selecionado nem
desabilitado). Motivo: simplificar a UI e evitar uma entrada de formulário
sem agência. Quando o projeto adicionar uma segunda unidade, o Select aparece
naturalmente.

---

## 5. Variáveis disponíveis nos templates (dicionário oficial)

Todas no namespace `brand`:

| Variável | Tipo | Default |
|----------|------|---------|
| `{{ brand.name }}` | string | `""` |
| `{{ brand.logo_url }}` | URL | `""` |
| `{{ brand.color_primary }}` | hex | `#FF5A1F` |
| `{{ brand.color_dark }}` | hex | `#0A0E27` |
| `{{ brand.color_text }}` | hex | `#1A1A1A` |
| `{{ brand.color_accent }}` | hex | `#C4FF00` |
| `{{ brand.whatsapp_url }}` | URL | `""` |
| `{{ brand.address }}` | string | `""` |

Adicionais herdados do Liquid renderer:

| Variável | Origem |
|----------|--------|
| `{{ contact.first_name }}` | `Contact.first_name` |
| `{{ contact.last_name }}` | `Contact.last_name` |
| `{{ contact.email }}` | `Contact.email` |
| `{{ contact.data.* }}` | `Contact.data` (qualquer campo) |
| `{{ campaign.subject }}` | `Campaign.subject` |
| `{{ campaign.data.* }}` | `Campaign.data` |

Para adicionar novos campos de identidade: editar `Brand.@default_brand` +
formulário de configuração de Brand. **Sem migração**.

---

## 6. Catálogo inicial de templates

Diretório: `priv/email_templates/library/`.

| Arquivo | Caso de uso | Categoria sugerida |
|---------|-------------|--------------------|
| `01-boas-vindas-matricula.mjml` | Onboarding de novo membro | — |
| `02-feliz-aniversario.mjml` | Aniversário | **Aniversariantes** |
| `03-oferta-limitada.mjml` | Promoção temporária | — |
| `04-newsletter-mes.mjml` | Newsletter periódica | — |
| `05-avaliacao-fisica.mjml` | Convite para avaliação | — |
| `06-convite-evento.mjml` | Eventos da unidade | — |
| `07-reativacao-aluno.mjml` | Reativação | **Ausentes 1-7 dias** |
| `08-indicacao-amigo.mjml` | Indicação | — |

Todos consomem `{{ brand.* }}` — mudança de identidade reflete imediatamente
no próximo render.

---

## 7. Pontos de extensão

| Quero adicionar... | Onde mexer | Migração? |
|--------------------|-----------|-----------|
| Nova categoria | `Categories.catalog/0` | Não |
| Novo campo de identidade | `Brand.@default_brand` + UI de config | Não |
| Novo tipo de contato (além de member/opportunity) | `data.evo_type` → mapeamento no controller | Não |
| Nova unidade | UI `units_live` | Não |
| Novo template | Adicionar `.mjml` em `priv/email_templates/library/` | Não |
