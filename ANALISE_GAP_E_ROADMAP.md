# Análise de Gap & Roadmap — Plataforma de E-mail Marketing Multiempresa (Fluxo Digital Tech)

> Documento de alinhamento entre o **Prompt Mestre** (visão de produto) e o **código atual** (fork do Keila já customizado pela Fluxo).
> Gerado em 2026-06-23. Sem alteração de código — este é o mapa que precede a construção.
>
> **Legenda de status:** ✅ Pronto · 🟡 Parcial · ❌ Ausente
> Toda afirmação está ancorada em arquivo real do repositório (`lib/...`).

---

## Sumário executivo

A base atual é um **fork do Keila** (Phoenix/Elixir, Swoosh, Oban, PostgreSQL) já bem evoluído pela Fluxo: multi-tenant por `projects`/`groups`, camada nova de `empresas` com CNPJ, contatos com double opt-in, campanhas (`mailings`) com agendamento/repetição, tracking de abertura/clique, automações por receita, NPS, IA de copy (OpenRouter), integração EVO (academias) e API pública.

**O que já é forte (fundação parcialmente pronta):**
- `List-Unsubscribe` + `List-Unsubscribe-Post` one-click (RFC 8058) **completos** — `lib/keila/mailings/builder.ex:363-364` + rota POST `lib/keila_web/router.ex:270`.
- Trava de envio por status do contato no worker (`lib/keila/mailings/worker.ex:56`) — não envia para `unsubscribed`/`unreachable`.
- Bounce soft/hard + complaint classificados, com webhook SES assinado (`lib/keila/mailings/recipient_actions/*`, `ses_webhook_controller.ex`).
- Validação de DNS (SPF/DKIM/DMARC) **existe** — porém **só no caminho SendWithKeila/cloud** (`extra/keila_cloud/dns.ex`), não para senders SMTP/SES próprios.
- Rate limiting por sender (`lib/keila/mailings/rate_limiter.ex`) e rampa adaptativa básica para domínio verificado vs não verificado.

**As 5 lacunas mais críticas vs. as "regras inegociáveis" (seção 8 do Prompt Mestre):**
1. **Sem gate de DNS universal** → hoje uma empresa com sender SMTP próprio dispara **sem** SPF/DKIM/DMARC validados. Viola a regra nº 1.
2. **Sem KYB real** → `empresas` valida só checksum de CNPJ; status é apenas `convidada`/`ativa`; não há aprovação do Master antes de liberar envio. Viola a regra nº 7.
3. **Sem `audit_logs`** → nenhuma trilha de auditoria; impersonation do Master não é registrada (`user_admin_controller.ex:127`). Viola a regra nº 8.
4. **Sem RBAC de empresa** → só existe `admin?` vs. não-admin; os perfis Dono/Operador/Visualizador/Compliance **não existem**; o campo `role` do convite **nunca é aplicado** (`invite_controller.ex`).
5. **Sem base legal / prova de consentimento / supressão como tabela** → contato não tem `legal_basis`; não há `consent_logs` nem `suppressions`; supressão é só o enum de status do contato.

**Conclusão estratégica:** o produto está a ~60% do "disparador competente", mas a **fundação de governança** (KYB, auditoria, RBAC multiempresa, base legal/consentimento, gate de DNS universal) é justamente o que o Prompt Mestre declara como inegociável — e é o que está mais ausente. O roadmap abaixo prioriza fechar essa fundação **antes** de features de V2/V3.

---

## 1. Visão geral do produto

Plataforma SaaS B2B multiempresa de e-mail marketing operada pela **Fluxo (Operadora LGPD)** para **empresas-clientes (Controladoras)**. Não é disparador: é operação de relacionamento + automação + venda + retenção, com governança, entregabilidade e isolamento por empresa desde o dia 1.

**Stack atual (herdada do Keila):** Elixir/Phoenix 1.7 · Ecto/PostgreSQL · Oban (filas) · Swoosh (envio, adapters SMTP/SES/Sendgrid/Mailgun/Postmark) · MJML + Liquid (editor) · ExRated (rate limit) · OpenRouter (IA).

**Modelo de domínio atual:**
```
Group (raiz) ─┬─ Account (cobrança/quota) ── Users
              └─ Project (tenant operacional) ── Empresa (CNPJ, opcional) ── Contacts/Campaigns/...
```
> O isolamento é **a nível de aplicação** (checagem `Auth.user_in_group?`), **não** row-level security. Funciona, mas o Prompt Mestre pede `company_id` em toda tabela de contato + RLS ou equivalente — hoje o equivalente é o `project_id` + scoping em query.

---

## 2. Mapa de módulos (spec § 6 × código)

| # | Módulo (spec) | Status | Onde está / o que falta |
|---|---|---|---|
| 1 | Dashboard Master | ❌ | Só há admin de instância (versão/update) `instance_admin_controller.ex` e admin de empresas/usuários/projetos. **Falta** dashboard agregado (volume, taxas, empresas em risco, domínios pendentes). |
| 2 | Dashboard da Empresa | 🟡 | Stats **por campanha** existem (`campaign_stats_live.ex`). **Falta** visão agregada da empresa (base, origens, automações ativas, saúde). |
| 3 | Cadastro de Empresas | 🟡 | `lib/keila/empresas/empresa.ex`: `nome`, `cnpj`, `email_responsavel`, `status(convidada/ativa)`, `project_id`. **Falta**: responsável/telefone/segmento/plano/limites diário-mensal/subdomínio/DPO/status KYB/observações/criado_por. |
| 4 | Usuários e Permissões | 🟡 | Login, reset de senha, convites (`invitations`), impersonation. **Falta**: MFA, lockout por tentativas, RBAC real (papéis), logs de acesso. |
| 5 | Contatos | 🟡 | `contact.ex`: email, nomes, `status(active/unsubscribed/unreachable)`, `data` (custom), `double_opt_in_at`, `external_id`. **Falta**: `legal_basis`, origem, consentimento (prova), telefone, último engajamento no contato, status `bounce`/`bloqueado` separados. |
| 6 | Listas e Segmentos | ✅🟡 | Segmentos dinâmicos com filtros (status, engajamento, custom data) `contacts/query.ex`; grupos por import. **Falta**: segmentos de higiene (inativo > X), por base legal. |
| 7 | Editor de E-mail | 🟡 | MJML + blocos + Liquid + preview + IA de copy. **Falta**: enforcement do link de descadastro, UTM automática, validação de links quebrados, preview mobile/desktop, templates **globais** da Fluxo. |
| 8 | Campanhas | 🟡 | Schema com assunto, preview_text, sender, segment, `scheduled_for`, status derivado, link público. **Falta**: A/B, reply-to explícito por campanha, aprovação antes do envio, status `bloqueada`. |
| 9 | Automações | 🟡 | 5 receitas hardcoded (`recipes.ex`), steps com delay, runs com status. **Falta**: "parar se converter", métricas por etapa, branch condicional, gatilho por clique, edição via UI. |
| 10 | Relatórios | 🟡 | Por campanha (enviados/abertos/clicados/bounce/complaint/unsub, séries temporais, top 20 links). **Falta**: por empresa, Master, receita atribuída, por domínio/segmento. |
| 11 | Compliance e Segurança | ❌ | Isolamento por project existe. **Falta**: `audit_logs`, criptografia de campo sensível, backup documentado, logs de import/export/permissão, aceite de termos/anti-spam. |
| 12 | Integrações | 🟡 | EVO (academias), API pública (`/api/v1/...`), webhook SES, NPS. **Falta**: webhooks assinados de saída, CRM, WhatsApp/SMS marketing, separação transacional × marketing, GA/Ads. |

---

## 3. Fluxo do Master (spec § 1–2)

**Hoje:** Master = usuário com permissão `administer_keila` no grupo raiz (`auth_session_plug.ex:15`). Pode listar/criar/excluir usuários, criar empresa (cria Project + Empresa + envia convite ao responsável), impersonar qualquer usuário **sem registro**.

**Alvo (gap):**
1. Cadastra empresa → **estado `pending_kyb`** (novo) em vez de já criar projeto liberado.
2. **Gate KYB**: valida CNPJ (✅ checksum já existe), site ativo, responsável, legitimidade → aprova/rejeita. **(❌ workflow inexistente)**
3. Define plano + limites diário/mensal. **(❌ campos inexistentes na empresa)**
4. Só após KYB aprovado **e** domínio validado → empresa pode disparar. **(❌ gate inexistente)**
5. Monitora reputação global e empresas em risco. **(❌ dashboard inexistente)**
6. Impersonation ("modo suporte") **com registro em `audit_logs` + banner "logado como"**. **(🟡 impersonation existe, auditoria não)**

---

## 4. Fluxo do Dono da Empresa (Controlador)

**Hoje:** ao aceitar o convite, vira membro do grupo do projeto (`invite_controller.ex`), o Master é removido do grupo, e a empresa passa a `ativa`. A partir daí opera contatos/campanhas do próprio projeto. **Não há distinção de papéis** dentro da empresa — todo membro é igual.

**Alvo (gap):**
- Papéis **Dono / Operador / Visualizador / Compliance** com RBAC por recurso. **(❌)**
- Dono configura domínio de envio + valida DNS antes do primeiro disparo. **(🟡 só no fluxo cloud)**
- Dono é ponto focal LGPD; cadastra DPO. **(❌ campo DPO inexistente)**
- Convite de membros já aplica o `role` escolhido. **(❌ `role` do convite é ignorado hoje)**

---

## 5. Fluxo de criação de campanha (spec § 8 regras 1, 2)

**Hoje:** rascunho → (agendar/enviar) → worker enfileira recipients → `builder.ex` injeta headers (incl. `List-Unsubscribe`) → Swoosh envia → tracking de abertura/clique → stats.

**Travas que faltam para cumprir as regras inegociáveis:**
- ❌ **Regra 1** — bloquear envio se o domínio do sender não tiver SPF/DKIM/DMARC alinhados validados (só existe no caminho cloud).
- ❌ **Regra 2** — bloquear campanha sem link de descadastro **no corpo** (o header existe sempre; o corpo depende do template — não há validação de presença de `{{ unsubscribe_link }}`).
- ❌ **Aprovação antes do envio** para conta nova / alto volume (regra 6).
- ❌ **Varredura de conteúdo** (phishing/links suspeitos, regra § 5).

---

## 6. Fluxo de importação de contatos (spec § 4 listas proibidas; § 8 regra 4)

**Hoje:** `lib/keila/contacts/import.ex` — CSV com detecção de separador, mapeamento de colunas, dedupe por email/external_id, atribuição de grupo, evento `import` registrado, validação de **sintaxe** de email.

**Falta (todas travas duras pedidas):**
- ❌ Validação **MX** + detecção de **descartáveis** + **spam traps**.
- ❌ **Bloqueio** de import com excesso de inválidos (ex.: > 10%).
- ❌ **Origem comprovada / base legal obrigatória** no import.
- ❌ Aviso de risco para lista comprada/raspada.
- ❌ Auditoria "quem importou, quando, de onde" (evento existe, mas sem usuário/IP).

---

## 7. Fluxo de configuração de domínio (spec § 3)

**Hoje:** Sender (`schemas/sender.ex`) tem `from_email`, `reply_to`, `verified_from_email`, config por adapter. Validação DNS real (`SPF/DKIM/DMARC` via `inet_res`) **só** em `extra/keila_cloud/dns.ex` + worker de verificação assíncrona — caminho **SendWithKeila/SES gerenciado**.

**Falta para o modelo multiempresa do Prompt Mestre:**
- ❌ **`email_domains` + `dns_checks`** como tabelas de primeira classe, por empresa.
- ❌ Verificação DNS **universal** (qualquer adapter), com **gate de envio**.
- ❌ Checagem de **alinhamento** DMARC (From alinha com SPF **ou** DKIM).
- ❌ **PTR/DNS reverso**, **Return-Path** próprio, **domínio de tracking (CNAME)** por empresa — hoje tracking usa o domínio do Keila (contamina reputação entre clientes).
- ❌ **Subdomínio de envio por empresa** com reputação isolada + pools (transacional/marketing/bulk).

---

## 8. Regras de LGPD (spec § 4) — estado real

| Requisito | Status | Evidência / Gap |
|---|---|---|
| Base legal por contato | ❌ | Sem campo `legal_basis` em `contact.ex`. |
| Prova de consentimento (texto, versão, timestamp, IP) | ❌ | Sem tabela `consent_logs`; só `double_opt_in_at`. |
| Double opt-in | ✅ | `double_opt_in_email_builder.ex` + `form_settings`. |
| LIA/RIPD (legítimo interesse, Art. 37) | ❌ | Inexistente. |
| Política vinculada + histórico de aceite | ❌ | `fine_print` no form, sem versionamento. |
| Direitos do titular Art. 18 (acesso/correção/portabilidade/eliminação/anonimização) | 🟡 | Export CSV + delete existem; **sem** anonimização, **sem** portal/fluxo do titular, **sem** API. |
| Preference center (frequência/tópicos) | ❌ | Só unsubscribe-all. |
| Supressão por empresa + bloqueio global | 🟡 | Trava por status do contato (`worker.ex:56`); **sem** tabela `suppressions` nem lista global. |
| Trava de envio p/ opt-out/hard-bounce/bloqueado | ✅🟡 | Status bloqueia; falta status `bloqueado` explícito + supressão permanente. |
| Listas compradas/raspadas (trava na importação) | ❌ | Sem detecção/bloqueio. |
| DPO/Encarregado por empresa | ❌ | Sem campo. |
| Retenção/expurgo automático | ❌ | Sem política. |
| Incidente/vazamento → ANPD | ❌ | Sem fluxo. |
| Criptografia em repouso de dados sensíveis | ❌ | Sem `Cloak`/campo cifrado; TLS em trânsito ✅. |

---

## 9. Regras de entregabilidade (spec § 3) — estado real

| Requisito | Status | Evidência / Gap |
|---|---|---|
| SPF/DKIM/DMARC validados | 🟡 | Só no caminho cloud (`extra/keila_cloud/dns.ex`); não para senders próprios. |
| Alinhamento DMARC | ❌ | Não há checagem de alinhamento From↔SPF/DKIM. |
| PTR / Return-Path / tracking CNAME | ❌ | Não configuráveis por empresa. |
| Gate de DNS antes do disparo | ❌ | Não bloqueia envio (universal). |
| `List-Unsubscribe` + one-click POST | ✅ | `builder.ex:363-364` + rota POST `router.ex:270`. |
| Descadastro em ≤ 2 dias | ✅ | Tempo real via status. |
| Score de saúde do domínio | ❌ | Sem `domain_reputation_scores`. |
| Google Postmaster / Yahoo FBL | ❌ | Só webhook SES; sem FBL externo. |
| Limiar spam < 0,3% / pausa automática | ❌ | Métricas existem por campanha; **sem** pausa automática por limiar. |
| Aquecimento responsável (rampa) | 🟡 | Rate limit verificado×não-verificado; **sem** cronograma de warmup. |
| Higiene (MX/descartável/spam trap) | ❌ | Só sintaxe. |
| Bounce soft×hard → supressão | ✅ | `recipient_actions/{soft,hard}_bounce.ex`. |
| Relatório de entregabilidade por domínio | ❌ | Só por campanha. |
| Subdomínio + reputação isolada por empresa | ❌ | Tracking/envio compartilham domínio. |
| Abstração de provedor (`sending_providers`) | 🟡 | Adapters Swoosh existem; sem tabela/roteamento por empresa/pool. |

---

## 10. Modelo de banco (spec § 7) — existe × falta

**Tabelas que já existem (mapeamento):**
`groups`/`projects`/`accounts`/`empresas` (≈ tenants/companies) · `users`+`roles`+`permissions`+`user_groups`+`role_permissions` (RBAC base, **subutilizado**) · `contacts` + `contacts.data` (custom fields) · `segments` · `campaigns` (`mailings`) · `mailings_recipients` (≈ campaign_recipients, com estados) · `templates` · `automations`+`automation_steps`+`automation_runs` · `senders` · `tracking` events/clicks/links (≈ email_events) · `credits`/billing (cloud) · `invitations` · `evo_units` · `media_assets` · `nps`.

**Tabelas do Prompt Mestre AUSENTES (a criar):**

| Tabela | Prioridade | Observação |
|---|---|---|
| `audit_logs` | 🔴 MVP | Regra inegociável nº 8. |
| `consent_logs` | 🔴 MVP | Prova de consentimento LGPD. |
| `suppressions` (empresa + global) | 🔴 MVP | Hoje só status do contato. |
| `email_domains` + `dns_checks` | 🔴 MVP | Gate de DNS por empresa. |
| `kyb_verifications` | 🔴 MVP | Gate do Master. |
| `usage_limits` (diário/mensal) | 🔴 MVP | Empresa só tem quota de crédito. |
| `data_subject_requests` (Art. 18) | 🟠 V2 | Portal do titular. |
| `preference_center_settings` | 🟠 V2 | Frequência/tópicos. |
| `bounce_logs` (soft/hard detalhado) | 🟠 V2 | Hoje é evento genérico. |
| `feedback_loop_events` | 🟠 V2 | Postmaster/Yahoo CFL. |
| `domain_reputation_scores` | 🟠 V2 | Score de saúde. |
| `sending_providers` | 🟠 V2 | Roteamento/abstração MTA por empresa. |
| `ip_pools` + `warmup_schedules` | 🟡 V3 | IP dedicado por plano. |
| `dpa_agreements` | 🟠 V2 | Contrato de operador no onboarding. |
| `webhooks` (saída assinada) | 🟠 V2 | Hoje só entrada SES. |
| Campos novos em `contacts` | 🔴 MVP | `legal_basis`, `source`, status `bounced`/`blocked`. |
| Campos novos em `empresas` | 🔴 MVP | plano, limites, subdomínio, DPO, kyb_status, criado_por, observações. |

> **Decisão de arquitetura recomendada:** manter `project_id` como a chave de isolamento (já presente em todas as tabelas de contato) e tratar `empresa` como a entidade de governança/comercial sobre o project. Não vale reescrever para `company_id` global agora — `project_id` **é** o `company_id` na prática.

---

## 11. Permissões por perfil (spec § 2) — gap de RBAC

**Hoje:** binário `admin?` (permissão `administer_keila` no grupo raiz) × membro de projeto. O sistema de `roles`/`permissions` do Keila **existe na base** mas só carrega o papel `root`; o `role` de convite (`owner`/`member`) **nunca é aplicado** na aceitação.

**Alvo:** ativar o RBAC já existente com 5 papéis:

| Perfil | Escopo | Implementação sugerida |
|---|---|---|
| Master Admin (Fluxo) | Global | Já existe (`administer_keila`). Adicionar auditoria obrigatória. |
| Dono da Empresa | Project | Novo role `owner` aplicado no convite + permissões `manage_users/domain/billing`. |
| Operador | Project | Role `operator`: `manage_campaigns/contacts/segments`, **sem** domínio/plano/usuários. |
| Visualizador | Project | Role `viewer`: só leitura. |
| Compliance/Suporte | Conforme alçada | Role `compliance`: leitura de logs/consent/opt-out. |

> Esforço **baixo-médio**: a infraestrutura (`roles`, `permissions`, `role_permissions`, `user_group_roles`) já está migrada — falta semear os papéis, aplicar no convite e adicionar plugs de autorização por recurso.

---

## 12. Roadmap MVP / V2 / V3

> Princípio do Prompt Mestre: **governança e entregabilidade são fundação, não V2.** O MVP abaixo prioriza fechar as 9 regras inegociáveis.

### 🔴 MVP — "fundação inegociável" (fecha as regras § 8)
1. **`audit_logs`** + middleware: logar ações críticas (login, import/export, permissão, impersonation, envio). *(regra 8)*
2. **KYB workflow** em `empresas`: status `pending_kyb → approved/rejected`, campos plano/limites/subdomínio/DPO/criado_por; **bloquear projeto até aprovação**. *(regra 7)*
3. **Gate de DNS universal**: tabelas `email_domains`+`dns_checks`; verificação SPF/DKIM/DMARC + alinhamento para **qualquer** sender; **bloquear envio** sem domínio validado. *(regra 1)*
4. **Enforcement de descadastro no corpo**: validar presença de `{{ unsubscribe_link }}` antes de permitir envio. *(regra 2)*
5. **`suppressions`** (empresa + global) + status de contato `bounced`/`blocked`; trava de envio consulta supressão. *(regra 3)*
6. **Higiene de import**: MX + descartáveis + bloqueio por % de inválidos + base legal obrigatória. *(regra 4)*
7. **Base legal + `consent_logs`** em contatos (consentimento/legítimo interesse/relação comercial). *(LGPD § 4)*
8. **RBAC de empresa** (5 papéis, ativando infra existente). *(perfis § 2)*
9. **Pausa automática** por limiar de spam/bounce + **aprovação manual** para alto volume de conta nova. *(regras 5, 6)*
10. **Dashboard Master** mínimo (empresas ativas/bloqueadas, domínios pendentes, campanhas em análise) + **Dashboard da Empresa** agregado.
11. **MFA para admins** + lockout por tentativas.

### 🟠 V2 — relacionamento e direitos
- Automações via UI + "parar se converter" + métricas por etapa + gatilho por **clique** (não abertura — MPP infla).
- A/B testing (assunto/conteúdo) + aprovação controlada de campanha.
- **Preference center** + **portal do titular (Art. 18)** + `data_subject_requests` + anonimização.
- **Postmaster/Yahoo CFL** (`feedback_loop_events`) + `domain_reputation_scores` + `bounce_logs`.
- Aquecimento automatizado (`warmup_schedules`) + `sending_providers` por empresa/pool.
- Templates globais da Fluxo · UTM automática · validação de links quebrados · preview mobile/desktop.
- Webhooks de saída assinados + API pública ampliada · `dpa_agreements` no onboarding.
- Retenção/expurgo automático + criptografia em repouso (Cloak).

### 🟡 V3 — inteligência e escala
- IA: melhor horário, score de engajamento/qualidade de lista, análise de risco pré-disparo, spam score.
- Dashboard de ROI + atribuição de receita via CRM.
- Omnichannel (WhatsApp/SMS) · detecção avançada de anomalia · IP dedicado por plano (`ip_pools`) · multi-idioma · BIMI/ARC.

---

## 13. Checklist técnico

- [ ] Migrar tabelas MVP: `audit_logs`, `consent_logs`, `suppressions`, `email_domains`, `dns_checks`, `kyb_verifications`, `usage_limits`; campos novos em `contacts`/`empresas`.
- [ ] Extrair o módulo `dns.ex` de `extra/keila_cloud` para o core e generalizar para qualquer sender.
- [ ] Plug de autorização de envio: `domain_validated? AND kyb_approved? AND not_over_limit? AND body_has_unsubscribe?`.
- [ ] Semear papéis (`owner/operator/viewer/compliance`) e aplicar `role` no `invite_controller`.
- [ ] Job de checagem periódica de DNS (Oban) + recomputação de score por domínio.
- [ ] Job de cálculo de taxa de spam/bounce por campanha → trigger de pausa automática.
- [ ] Validador de import: MX (`inet_res:lookup(:mx)`), lista de domínios descartáveis, threshold de inválidos.
- [ ] Domínio de tracking por empresa (CNAME) no `builder.ex` (hoje fixo).
- [ ] Testes: cobertura dos gates inegociáveis (cada regra § 8 = um teste que **falha o envio**).

## 14. Checklist de segurança

- [ ] MFA/2FA obrigatório para Master e Donos de empresa.
- [ ] Lockout + rate limit de login (hoje ausente).
- [ ] Auditoria de impersonation + banner "modo suporte" visível.
- [ ] Criptografia em repouso de PII sensível (Cloak/Vault) — email/telefone/CNPJ do responsável.
- [ ] Assinatura HMAC em **todos** os webhooks (entrada e saída), não só SES.
- [ ] Isolamento por `project_id` verificado em testes de autorização (tentar cross-tenant deve falhar).
- [ ] Aceite de termos + política anti-spam registrado por usuário/empresa.
- [ ] Backup + plano de incidente/vazamento com notificação ANPD.

## 15. Checklist de operação

- [ ] Painel de domínios pendentes/falhos por empresa (Master).
- [ ] Alertas: empresa acima do limiar de spam/bounce; domínio caiu; KYB pendente há > X dias.
- [ ] Runbook de pausa/retomada de empresa/domínio.
- [ ] Processo de aprovação manual de alto volume (fila de revisão).
- [ ] Política de retenção/expurgo agendada (Oban) + relatório de expurgo.
- [ ] Onboarding com DPA assinado antes de liberar envio.

## 16. Sugestões de telas (novas/ajustadas)

1. **Master › Empresas**: lista com status KYB, plano, % spam/bounce, domínios pendentes; ação Aprovar/Rejeitar/Pausar.
2. **Master › Dashboard**: cartões (empresas ativas/bloqueadas/teste, volume, taxas médias, em risco).
3. **Empresa › Domínio de envio**: assistente de DNS (mostra registros SPF/DKIM/DMARC/CNAME a publicar + botão "verificar agora" + estado de alinhamento).
4. **Empresa › Onboarding LGPD**: aceite de DPA, cadastro de DPO, política de privacidade.
5. **Contatos › Import**: etapa de validação (inválidos/descartáveis/% bloqueio) + seleção de base legal + origem.
6. **Campanha › Pré-voo**: checklist de envio (domínio ✅, descadastro ✅, supressão aplicada, score de risco) antes de liberar.
7. **Empresa › Preference center / Portal do titular** (V2).
8. **Empresa › Usuários**: convite com seleção de papel (Dono/Operador/Visualizador/Compliance).

## 17. Critérios de aceite (das regras inegociáveis)

1. Sender com domínio **não** validado → tentativa de envio **bloqueada** com mensagem clara. ✅ teste obrigatório.
2. Campanha sem link de descadastro no corpo → **não** pode ser enviada.
3. Envio para contato em supressão/opt-out/hard-bounce → **nunca** ocorre (verificado no worker).
4. Import com > X% inválidos ou sem base legal → **bloqueado**.
5. Empresa ultrapassa limiar de spam → **pausa automática** registrada em auditoria.
6. Conta nova + alto volume → entra em **fila de aprovação**, não dispara direto.
7. Empresa sem KYB aprovado → projeto **não libera** envio.
8. Toda ação crítica (incl. impersonation) gera registro em `audit_logs`.
9. Usuário de uma empresa **não** acessa dados de outra (teste cross-tenant falha).

## 18. Pontos de atenção anti-spam e anti-bloqueio

- **Domínio de tracking compartilhado é o maior risco atual**: hoje cliques/aberturas usam o domínio do Keila para todos os clientes (`builder.ex`). Uma lista ruim de uma empresa pode manchar a reputação do domínio de tracking de **todas**. → CNAME por empresa é prioridade.
- **Gatilhos por "abertura" são não confiáveis** (Apple Mail Privacy Protection infla aberturas): automações e segmentos de engajamento devem priorizar **clique**.
- **Complaint hoje vira `unsubscribed`** (`complaint.ex:27`); avaliar tratar como supressão permanente (mais perto de hard bounce) para não reativar por engano.
- **Sem aquecimento** estruturado: domínio/IP novo disparando volume cheio = bloqueio rápido. Rampa obrigatória.
- **Provedor de envio fora do Brasil** (SES/Sendgrid) = **transferência internacional** de dados sob LGPD → registrar base e cláusulas.
- **Bot detection limitado** (2 user-agents hardcoded em `tracking.ex`): aberturas/cliques de bots inflam métricas e enganam automações.

---

## Próximo passo recomendado

Sugiro atacar o MVP na ordem que **destrava valor + reduz risco jurídico** mais rápido:

> **Sprint 1 (fundação de governança):** `audit_logs` + KYB workflow + RBAC de empresa (ativar infra existente).
> **Sprint 2 (entregabilidade inegociável):** gate de DNS universal + enforcement de descadastro + `suppressions`.
> **Sprint 3 (LGPD + higiene):** base legal + `consent_logs` + validação de import (MX/descartável/threshold).

Posso começar por qualquer um destes itens já implementando no código — é só dizer qual.
