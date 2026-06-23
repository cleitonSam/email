# Plataforma de E-mail Marketing Multiempresa — Fluxo Digital Tech
## Documento de Design (18 entregáveis) + Status de Implementação

> Documento autoritativo de produto. Reflete o **código real** (fork do Keila — Phoenix/Elixir, Ecto/PostgreSQL, Oban, Swoosh, MJML+Liquid). Complementa `ANALISE_GAP_E_ROADMAP.md`.
> **Legenda:** ✅ Implementado · 🟡 Parcial · ❌ Pendente · Atualizado em 2026-06-23.

---

## 1. Visão geral do produto

Operação profissional de relacionamento, automação, venda e retenção — **não** um disparador. Multiempresa com governança, entregabilidade e LGPD como fundação. A **Fluxo é Operadora** (LGPD); cada **empresa-cliente é Controladora**. O **Master Admin** cadastra empresas, valida KYB, define plano/limites e monitora reputação; cada **empresa** opera só a própria base, isolada por `project_id`.

**Stack:** Elixir/Phoenix 1.7 · Ecto/PostgreSQL · Oban (filas) · Swoosh (SMTP/SES/Sendgrid/Mailgun/Postmark) · MJML+Liquid (editor) · ExRated (rate limit) · OpenRouter (IA).

**Estado atual:** MVP de governança/entregabilidade/LGPD **implementado** (Sprints 1–3). Faltam camadas de V2/V3 (portal do titular, dashboards consolidados, FBL/warmup, IA avançada).

---

## 2. Mapa de módulos (× código real)

| Módulo | Status | Onde está |
|---|---|---|
| Dashboard Master | ❌ | (pendente — só admin de instância/empresas/usuários) |
| Dashboard da Empresa | 🟡 | stats por campanha (`campaign_stats_live`) |
| Cadastro de Empresas + KYB | ✅ | `Keila.Empresas`, `/admin/empresas` |
| Usuários e Permissões (RBAC) | ✅🟡 | `Keila.Rbac`, papéis owner/operator/viewer/compliance |
| Contatos (+ base legal) | ✅🟡 | `Keila.Contacts`, `contacts.legal_basis/source` |
| Listas e Segmentos | ✅ | `Keila.Contacts.Segment`, filtros dinâmicos |
| Editor de E-mail | 🟡 | MJML+blocos+Liquid+IA; falta UTM auto/preview mobile |
| Campanhas | ✅🟡 | `Keila.Mailings`; falta A/B, aprovação |
| Automações | 🟡 | `Keila.Automations` (receitas); falta UI/branch |
| Relatórios | 🟡 | por campanha; faltam consolidados |
| Compliance e Segurança | ✅🟡 | `audit_logs`, isolamento por project; falta criptografia de campo |
| Integrações | 🟡 | EVO, API pública, webhook SES, NPS |

---

## 3. Fluxo do Master Admin ✅ (núcleo)

1. Cadastra empresa em `/admin/empresas` (CNPJ validado, plano, limites, domínio, DPO).
2. **Gate KYB** — aprova/rejeita/bloqueia/reativa. Sem KYB aprovado → **envio bloqueado** (`Keila.Empresas.pode_enviar?` consultado no worker).
3. Define plano e limites (diário/mensal) na empresa.
4. **Impersonation** ("modo suporte") registrada em `audit_logs` (`Keila.Auditoria`).
5. ❌ Dashboard global de reputação/risco (pendente).

## 4. Fluxo do dono da empresa ✅🟡

1. Aceita convite → vira dono do projeto, recebe papel `owner` (`Keila.Rbac`).
2. Configura **domínio de envio** em `/projects/:id/domains` e verifica SPF/DMARC.
3. Importa contatos, cria listas/segmentos, campanhas, automações — isolado no próprio `project_id`.
4. Convida equipe com papel (operator/viewer/compliance).
5. 🟡 Faturamento/plano (campos existem; tela self-service pendente).

## 5. Fluxo de criação de campanha ✅🟡 (gates inegociáveis ativos)

Rascunho → (enviar/agendar) → **gates** em `Mailings.deliverable_check/1` + `deliver_campaign`:
- ❌→✅ **Sem descadastro no corpo** → bloqueia (regra 2).
- ❌→✅ **Domínio não verificado** → bloqueia (regra 1, `Keila.Deliverability`).
- ✅ Sem remetente → bloqueia.
- Worker (por destinatário): pula supressão + empresa com KYB ok.
- 🟡 A/B testing e aprovação manual: pendentes.

## 6. Fluxo de importação de contatos ✅🟡

CSV (`Keila.Contacts.Import`) → mapeamento de colunas PT/EN → dedupe → **higiene** (`EmailHygiene`: sintaxe + **pula descartáveis**) → carimba `source="import"` e `legal_basis="legitimate_interest"`. Evento `import` registrado.
- 🟡 Threshold-blocking por % de inválidos (helper pronto; UI pendente).
- 🟡 MX em massa (helper `valid_mx?` pronto; não inline por performance).

## 7. Fluxo de configuração de domínio ✅ (universal)

`/projects/:id/domains` → cadastra domínio → `Keila.Deliverability.verificar_dominio` checa **SPF** (TXT `v=spf1`) e **DMARC** (`_dmarc` TXT `v=DMARC1; p=`), DKIM best-effort → status `verified/failed/pending`. **Gate progressivo:** domínio cadastrado e não-verificado bloqueia; sem registro libera (legado), salvo `REQUIRE_VERIFIED_DOMAIN=true`.
- ❌ Return-Path próprio e domínio de tracking (CNAME) por empresa (pendente).

## 8. Regras de LGPD

| Requisito | Status | Implementação |
|---|---|---|
| Origem/data/IP do contato | ✅ | `contacts.source`, `consent_logs.ip/user_agent/occurred_at` |
| Base legal | ✅ | `contacts.legal_basis` (consent/legitimate_interest/contract) |
| Prova de consentimento | ✅ | `consent_logs` + `Keila.Consent` (texto, política, double opt-in) |
| Double opt-in | ✅ | `double_opt_in_email_builder` + forms |
| Descadastro obrigatório | ✅ | List-Unsubscribe one-click + enforce no corpo |
| Supressão por empresa + global | ✅ | `suppressions` + `Keila.Suppressions` |
| Trava p/ opt-out/bounce/bloqueado | ✅ | worker + supressão alimentada por bounce/complaint/unsub |
| Bloqueio de descartáveis na importação | ✅ | `EmailHygiene.disposable?` |
| Auditoria de import/edição | 🟡 | evento `import`; auditoria completa de contato pendente |
| DPO/Encarregado por empresa | ✅ | `empresas.dpo_nome/dpo_email` |
| Exclusão/anonimização | 🟡 | delete existe; anonimização + portal do titular pendentes |
| LIA/RIPD (legítimo interesse) | ❌ | pendente |
| Preference center | ❌ | pendente (V2) |

## 9. Regras de entregabilidade

| Requisito | Status |
|---|---|
| SPF/DKIM/DMARC validados por empresa | ✅ (`Keila.Deliverability`) |
| Verificação de DNS antes de liberar disparo | ✅ (gate em `deliver_campaign`) |
| List-Unsubscribe one-click (RFC 8058) | ✅ |
| Bounce soft/hard + complaint → supressão | ✅ |
| Score de saúde do domínio | 🟡 (estado por domínio; score numérico pendente) |
| Postmaster/Yahoo FBL | ❌ (V2) |
| Pausa automática por limiar de spam/bounce | 🟡 (bloqueio manual existe; automático pendente) |
| Aquecimento/warmup | ❌ (V2) |
| Return-Path / tracking CNAME por empresa | ❌ |
| Relatório de entregabilidade por domínio | 🟡 |

## 10. Modelo de banco de dados

**Implementadas (mapeamento):** `empresas` (companies+KYB+plano+limites+DPO) · `projects`/`groups`/`accounts` (tenant/isolamento) · `users`/`roles`/`permissions`/`user_groups`/`user_group_roles` (RBAC) · `contacts` (+`legal_basis`,`source`) · `segments` · `mailings_campaigns` · `mailings_recipients` (≈ campaign_recipients) · `templates` · `automations`/`automation_steps`/`automation_runs` · `mailings_senders` · `tracking` events/clicks/links (≈ email_events) · **`audit_logs`** ✅ · **`suppressions`** ✅ · **`consent_logs`** ✅ · **`email_domains`** ✅ · `invitations` · billing/credits.

**Pendentes:** `dns_checks` (histórico — hoje estado em `email_domains`) · `sending_providers` (roteamento por empresa) · `feedback_loop_events` · `domain_reputation_scores` · `ip_pools`/`warmup_schedules` · `data_subject_requests` (Art. 18) · `preference_center_settings` · `kyb_verifications` (hoje campos em `empresas`) · `usage_limits` (campos em `empresas`).

> **Decisão de arquitetura:** `project_id` **é** o `company_id` na prática (isolamento a nível de app já presente em toda tabela de contato). `empresa` é a camada de governança/comercial sobre o project.

## 11. Permissões por perfil ✅🟡

`Keila.Rbac.can?/3` (reaproveita papéis/permissões do Keila), default não-quebra (sem papel = acesso total, legado). Papéis criados no boot (`Keila.Auth.ensure_company_roles!`), aplicados no convite.

| Perfil | Permissões |
|---|---|
| **Master (Fluxo)** | `administer_keila` (global) + auditoria de tudo |
| **Dono** (owner) | manage_company_users/domain/billing + campaigns/contacts/segments + reports |
| **Operador** | manage_campaigns/contacts/segments + view_reports |
| **Visualizador** | view_reports |
| **Compliance** | view_compliance_logs + view_reports |

🟡 Enforcement aplicado hoje só na tela de Domínios; expandir para demais controllers é incremental.

## 12. Roadmap

- **MVP** ✅ **CONCLUÍDO** — multiempresa+isolamento, KYB, RBAC, validação de domínio (SPF/DMARC) com gate, contatos+import com higiene, listas/segmentos, editor com descadastro obrigatório, campanhas agendadas, supressão por empresa+global, auditoria, base legal+consent_logs, super admin.
- **V2** — automações via UI + A/B + aprovação · preference center · **portal do titular (Art. 18)** · Postmaster/Yahoo FBL · warmup automatizado · IPs dedicados por plano · **dashboards Master/Empresa** · webhooks de saída assinados · pausa automática por limiar · Return-Path/tracking CNAME por empresa · threshold-blocking de import com UI · ampliar enforcement RBAC.
- **V3** — IA (assunto/copy/horário/score) · dashboard de ROI · atribuição de receita via CRM · omnichannel (WhatsApp/SMS) · detecção avançada de anomalia · multi-idioma · BIMI/ARC.

## 13. Checklist técnico

- [x] `audit_logs`, `suppressions`, `email_domains`, `consent_logs` + campos KYB/base legal migrados.
- [x] Gate de DNS universal (`Keila.Deliverability`) com bloqueio de envio.
- [x] Gate de descadastro no corpo (`Mailings.deliverable_check`).
- [x] Worker barra KYB não-liberado + supressão.
- [x] RBAC semeado no boot + aplicado no convite.
- [ ] Domínio de tracking por empresa (CNAME) no `builder.ex`.
- [ ] Job de recomputação de score por domínio + pausa automática por limiar.
- [ ] Threshold-blocking de import com UI; MX em massa assíncrono.

## 14. Checklist de segurança

- [x] Auditoria de impersonation + ações críticas (`audit_logs`).
- [x] Isolamento por `project_id`.
- [ ] MFA obrigatório p/ admins (campo/fluxo pendente).
- [ ] Lockout por tentativas de login.
- [ ] Criptografia em repouso de PII sensível (Cloak).
- [ ] HMAC em todos os webhooks (entrada e saída).
- [ ] Backup documentado + plano de incidente/ANPD.

## 15. Checklist de operação

- [x] Aprovar/bloquear empresa e KYB (`/admin/empresas`).
- [x] Verificar domínio (`/projects/:id/domains`).
- [ ] Painel de domínios pendentes/falhos (Master).
- [ ] Alertas: spam/bounce acima do limiar, KYB pendente > X dias.
- [ ] Fila de aprovação manual de alto volume.
- [ ] Política de retenção/expurgo agendada (Oban).
- [ ] DPA assinado no onboarding.

## 16. Sugestões de telas

1. ✅ Master › Empresas (KYB: aprovar/rejeitar/bloquear).
2. ✅ Empresa › Domínios de envio (assistente SPF/DMARC + verificar).
3. ❌ Master › Dashboard (cartões: ativas/bloqueadas, volume, taxas, risco).
4. ❌ Empresa › Onboarding LGPD (DPA, DPO, política).
5. 🟡 Contatos › Import (validação/inválidos/base legal — higiene ativa, UI de threshold pendente).
6. ❌ Campanha › Pré-voo (checklist: domínio ✅, descadastro ✅, risco) — gates existem no backend.
7. ❌ Empresa › Preference center / Portal do titular (V2).
8. ✅ Empresa › Usuários (convite com papel).

## 17. Critérios de aceite (regras inegociáveis)

1. ✅ Sender com domínio não validado → envio bloqueado (`deliver_campaign`).
2. ✅ Campanha sem descadastro no corpo → não envia/agenda.
3. ✅ Envio p/ supressão/opt-out/hard-bounce → nunca ocorre (worker).
4. 🟡 Import com excesso de inválidos → bloqueia (helper pronto; UI pendente). Descartáveis já pulados.
5. 🟡 Spam acima do limiar → pausa (manual hoje; automático pendente).
6. ❌ Conta nova + alto volume → fila de aprovação (pendente).
7. ✅ Empresa sem KYB aprovado → não envia.
8. ✅ Toda ação crítica (incl. impersonation) em `audit_logs`.
9. ✅ Empresa não acessa dados de outra (isolamento por project).

## 18. Pontos de atenção anti-spam e anti-bloqueio

- **Domínio de tracking compartilhado** (`builder.ex`) — maior risco atual: uma lista ruim contamina a reputação de todos. → CNAME por empresa é prioridade.
- **Gatilhos por "abertura" não confiáveis** (Apple MPP infla aberturas): automações/segmentos de engajamento devem priorizar **clique**.
- **Complaint** hoje vira `unsubscribed` + supressão — avaliar tratar como supressão permanente equiparada a hard bounce.
- **Sem warmup** estruturado: domínio/IP novo disparando volume cheio = bloqueio. Rampa obrigatória (V2).
- **Provedor fora do Brasil** (SES/Sendgrid) = transferência internacional sob LGPD → registrar base/cláusulas.
- **Bot detection limitado** (`tracking.ex`): aberturas/cliques de bots inflam métricas e enganam automações.

---

### Implementado nesta fase (commits)
- Sprint 1 — KYB · `audit_logs`/`Keila.Auditoria` · `suppressions`/`Keila.Suppressions` · super admin · **RBAC** (`Keila.Rbac`).
- Sprint 2 — enforce de descadastro (regra 2) · gate de DNS (regra 1, `Keila.Deliverability` + `email_domains`).
- Sprint 3 — base legal/origem · `consent_logs`/`Keila.Consent` · higiene de import (`EmailHygiene`).

**Próximo recomendado:** Portal do titular (Art. 18) + Dashboards Master/Empresa + pausa automática por limiar.
