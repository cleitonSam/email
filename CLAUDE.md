# CLAUDE.md — Fluxo Email MKT

Guia de contexto para o Claude Code. Carregado automaticamente ao trabalhar nesta pasta.
**Idioma:** responder sempre em **português (pt-BR)**.

## O que é este projeto

Plataforma SaaS B2B **multiempresa** de e-mail marketing da **Fluxo Digital Tech**, baseada num **fork do Keila** (`app: :keila`, versão 0.14.7). Não é um "disparador": é operação profissional de relacionamento, automação, venda e retenção, com **governança, entregabilidade e LGPD como fundação desde o dia 1**.

- **Operadora (LGPD):** a Fluxo (a plataforma).
- **Controladora:** cada empresa-cliente (tenant `empresas`, com CNPJ, KYB, plano, limites, DPO).
- **Master Admin Fluxo:** cadastra empresas, aprova KYB, define plano/limites, bloqueia/desbloqueia, impersona com auditoria.

## Stack

Elixir ~> 1.18 · Phoenix 1.7 (LiveView + controllers) · Ecto/PostgreSQL · Oban (filas) · Swoosh + ExAWS/SES (envio) · MJML + Solid/Liquid (templates) · Argon2 (senha, **sem MFA**) · OpenRouter (IA, default `google/gemini-2.5-flash`) · Tailwind + esbuild (assets) · Bandit (server) · ExRated (rate limit).

## Comandos (via aliases do mix.exs)

```bash
mix setup            # deps.get + ecto.setup + npm install (assets)
mix ecto.setup       # ecto.create + ecto.migrate + seeds
mix ecto.reset       # drop + setup
mix ecto.migrate     # rodar migrations
mix phx.server       # subir app (dev)
mix test             # cria/migra DB de teste e roda testes
mix assets.build     # tailwind + esbuild
mix format           # formatar (.formatter.exs)
```
Requer `DATABASE_URL`/`DB_URL` (ver `.env.example`). Versões fixadas em `.tool-versions`.

## Arquitetura multi-tenant

```
Account (billing legado por grupo)
  └─ Group (raiz; CTE recursiva via parent_id)
       └─ Project  ──1:1──►  Empresa (tenant de governança: CNPJ, KYB, plano, limites, DPO)
            ├─ Contacts (legal_basis, source, status, double_opt_in_at)
            ├─ Segments / Forms / Templates / Senders / EmailDomains
            ├─ Campaigns → Recipients → Tracking (links/clicks/events)
            ├─ Automations → Steps → Runs
            └─ NPS
```
- **Isolamento = nível de aplicação por `project_id`** (não RLS). `project_id` é, na prática, o `company_id`. Acesso exige pertencimento ao Group: `lib/keila_web/helpers/project/project_plug.ex:13-21` (404 se não-membro).
- **Empresa** é a entidade de governança/comercial sobre o Project. Gate de envio depende de KYB aprovado.

## Status de implementação (resumo)

**Fundação inegociável JÁ wired em runtime (~70-75% de um produto B2B competente):**
- Gate de KYB no envio (`lib/keila/empresas/empresas.ex:93-111`, `worker.ex:41,67-75`).
- Supressão por e-mail empresa+global, sobrevive a recriação de contato (`lib/keila/suppressions.ex`); supressão automática em hard bounce/complaint/unsubscribe (`recipient_actions/*`).
- Enforce de descadastro no corpo + List-Unsubscribe One-Click (`mailings.ex:1063-1102`, `builder.ex:361-365`).
- SPF/DMARC no core com gate (`lib/keila/deliverability.ex`); pausa automática por reputação spam>0,3% / hard bounce>5% (`lib/keila/reputation.ex`).
- audit_logs + impersonation auditada (`lib/keila/auditoria.ex`, `user_admin_controller.ex:127-140`).
- Consentimento + double opt-in via HMAC; `consent_logs`, `data_subject_requests` (7 tipos do Art.18) no backend.

**Lacunas críticas (enforcement/UI, não fundação) — ordem sugerida:**
1. **RBAC definido mas NÃO aplicado** — `Keila.Rbac.can?/3` só é consultado em 1 ação (`domain_controller.ex:105`); operador/visualizador/compliance têm o mesmo poder do dono. Default permissivo (`rbac.ex:28-35`). **Maior buraco de segurança multiempresa.**
2. **Sem MFA e sem lockout de login** (crítico p/ Master e Dono).
3. **Automações não enviam de verdade** — `sync_worker.ex:231-253` só loga e marca `:sent`.
4. **Art.18 + supressão sem UI** (backend completo, sem rota/controller/LiveView).
5. **Limites diário/mensal por empresa são declarativos** (nunca aplicados; sem tabela de usage).
6. **Domínio de tracking compartilhado** (`builder.ex`) — maior risco de contaminação de reputação cross-tenant; falta CNAME por empresa.
7. Sem Dashboard Master agregado; relatórios só por campanha; sem warmup/rampa.

## Convenções

- **Status nos docs:** `[OK]` implementado · `[PARCIAL]` parcial · `[AUSENTE]` pendente.
- Estados de domínio em PT-BR no código novo da Fluxo (ex.: KYB `pendente/aprovado/rejeitado`).
- **Antes de apagar/sobrescrever:** confirmar; é repo git → recuperável, mas pedir OK em remoções de docs.
- Toda ação crítica deve gerar `audit_log`.

## Documentos de referência (na raiz)

- `DESIGN_PLATAFORMA_FLUXO.md` — **doc autoritativo**: os 18 entregáveis de design + status, ancorado no código real.
- `ANALISE_GAP_E_ROADMAP.md` — gap analysis e roadmap MVP/V2/V3.
- `GUIA_ADMIN_MULTI_TENANT.md` — operação multiempresa / super admin.
- `MELHORIAS_RECOMENDADAS.md` — melhorias priorizadas (ex.: i18n pt-BR).
- `DEPLOYMENT.md` — deploy em produção (Docker Compose).
- `CHANGELOG.md` — histórico.

## Ao iniciar uma sessão

Para saber o estado atual: `git -C <pasta email> log --oneline -10` e `git status`. O histórico recente registra o que já foi implementado (KYB, RBAC, gate de DNS, base legal, consentimento, supressão, pausa automática, Art.18).
