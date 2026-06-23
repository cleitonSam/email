# Plataforma de E-mail Marketing Multiempresa — Fluxo Digital Tech
## Documento de Design (18 entregaveis) + Status de Implementacao

> Documento autoritativo de produto, ancorado no **codigo real** do fork do Keila (Phoenix/Elixir, Ecto/PostgreSQL, Oban, Swoosh, MJML+Liquid, OpenRouter).
> Gerado por mapeamento direto do repositorio. Legenda: [OK] implementado · [PARCIAL] parcial · [AUSENTE] pendente. Data: 2026-06-23.

---

## 1. Visao geral do produto

A **Fluxo Email MKT** nao e um "disparador de emails". E uma **plataforma de operacao profissional de relacionamento, automacao, venda e retencao**, multiempresa (multi-tenant), na qual **governanca, entregabilidade e LGPD sao fundacao desde o dia 1** — nao add-ons. A diferenca pratica esta cabeada no proprio caminho de envio: antes de qualquer mensagem sair, o sistema valida KYB da empresa, base legal/supressao do contato, descadastro no corpo e SPF/DMARC do dominio remetente (`lib/keila/mailings/worker.ex:38-86`, `lib/keila/mailings/mailings.ex:597-633`).

### Modelo de responsabilidade LGPD

| Papel LGPD | Quem | Funcao |
|---|---|---|
| **Operadora** | Fluxo (a plataforma) | Trata dados em nome da empresa-cliente; oferece trilhas de auditoria, supressao, prova de consentimento e gate de envio |
| **Controladora** | Empresa-cliente (tenant `empresas`) | Define finalidade e base legal; responde pelos titulares; possui DPO (`dpo_nome`/`dpo_email` em `lib/keila/empresas/empresa.ex:53-54`) |
| **Operador da plataforma** | Master Admin Fluxo | Opera o todo: aprova KYB, cadastra empresas, bloqueia/desbloqueia, impersona com auditoria (`lib/keila_web/controllers/empresa_admin_controller.ex`, `user_admin_controller.ex:127-140`) |

### Stack tecnico real

| Camada | Tecnologia | Evidencia no codigo |
|---|---|---|
| Runtime/Web | Elixir + Phoenix (LiveView + Controllers) | `lib/keila_web/**` |
| Persistencia | Ecto + PostgreSQL | `priv/repo/migrations/**`, schemas em `lib/keila/**` |
| Filas/Jobs | Oban (unique por recipient, backoff/retry) | `lib/keila/mailings/worker.ex:7-28` |
| Envio | Swoosh + adapter SES (Configuration Set) | `lib/keila/mailer.ex`, `lib/keila/mailings/sender_adapters/ses.ex` |
| Templating | MJML + Liquid (brand kit, CSS mobile defensivo) | `lib/keila/mailings/builder/mjml.ex`, `lib/keila/mailings/builder.ex:46-96` |
| IA | OpenRouter (Claude/GPT/Gemini, default `google/gemini-2.5-flash`) | `lib/keila/integrations/open_router.ex`, `lib/keila/ai/email_editor.ex` |
| Auth | Argon2 (sem MFA hoje) | `lib/keila/auth/schemas/user.ex:78-114` |

### Modelo de dominio multi-tenant

O isolamento usa a hierarquia de **Groups** herdada do Keila, estendida pela entidade **Empresa**:

```
Account (billing legado por grupo)
   └─ Group (raiz da conta; CTE recursiva parent_id)
        └─ Project  ←──── 1:1 ────►  Empresa (tenant de governanca: CNPJ, KYB, plano, limites, DPO)
              ├─ Contacts (legal_basis, source, status, double_opt_in_at)
              ├─ Segments / Forms / Templates / Senders / EmailDomains
              ├─ Campaigns → Recipients → Tracking (links/clicks/events)
              ├─ Automations → Steps → Runs
              └─ NPS (pesquisas/envios/respostas)
```

- **Isolamento**: acesso ao projeto exige pertencimento ao Group (`lib/keila_web/helpers/project/project_plug.ex:13-21`, 404 se nao-membro).
- **Empresa como tenant de governanca**: criada pelo Master, vincula `project_id`, valida CNPJ com digitos verificadores (`lib/keila/empresas/empresa.ex:140-184`) e governa o gate de envio via KYB.
- **RBAC**: infra granular completa (Role/Permission/UserGroupRole com CTE recursiva, `lib/keila/auth/auth.ex:318-360`) e os 4 papeis de empresa (owner/operator/viewer/compliance) criados no boot (`auth.ex:138-205`).

### Maturidade atual (~70-75% de um produto B2B competente)

A **fundacao inegociavel esta wired em runtime** e operante: gate de KYB no envio, supressao por email (empresa + global) sobrevivendo a recriacao de contato, enforce de descadastro no corpo, SPF/DMARC no core, supressao automatica em bounce/complaint/unsubscribe, pausa automatica por reputacao, audit_logs com impersonation auditada, consentimento + double opt-in via HMAC. O **dominio LGPD** (consent_logs imutaveis, suppressions com indices parciais, data_subject_requests com os 7 tipos do Art.18) esta bem construido.

As lacunas que rebaixam o percentual sao de **operacao/exposicao**, nao de fundacao:
- **RBAC definido mas nao aplicado**: `Keila.Rbac.can?/3` so e consultado em 1 acao (gestao de dominio, `domain_controller.ex:105`); operator/viewer/compliance tem na pratica o mesmo poder do owner em campanhas/contatos/segmentos/templates. **Risco de privilege-equivalence.**
- **Sem MFA/2FA e sem lockout de login** (critico para Master e Dono num SaaS multiempresa).
- **Automacoes nao enviam de verdade** (`sync_worker.ex:231-253` apenas loga e marca `:sent`).
- **Direitos do titular (Art.18) e gestao de supressao sem UI** (backend completo, sem rota/controller/LiveView).
- **Planos/limites por empresa sao declarativos** (`limite_diario`/`limite_mensal` nunca aplicados; sem tabela de usage).
- **Sem Dashboard Master agregado** e relatorios so por campanha.

Veredito: **MVP de governanca/entregabilidade/LGPD pronto e endurecido; faltam enforcement de RBAC, hardening de auth, ativacao real das automacoes e a camada de UI/relatorios para tornar a operacao multiempresa segura e completa.**

## 2. Mapa de modulos

| # | Modulo | Status | Onde esta / o que falta |
|---|---|---|---|
| 1 | **Dashboard Master** | [AUSENTE] | Existem admins por entidade (`empresa_admin_controller.ex`, `user_admin_controller.ex`, project/instance/shared_sender admin), todos sob `is_admin?`. **Falta** a visao global agregada (volume, taxas, empresas em risco, dominios pendentes). Nao ha view consolidada. |
| 2 | **Dashboard Empresa** | [PARCIAL] | Ha stats por campanha em tempo real via LiveView (`lib/keila_web/live/campaign_stats_live.ex`, `mailings.ex:948-998`). **Falta** visao agregada da empresa: base ativa, origens, automacoes ativas, saude/reputacao, taxa media. |
| 3 | **Cadastro de Empresas** | [PARCIAL] | Schema, validacao de CNPJ, status operacional, cadastro pelo Master criando Project+Empresa+convite owner (`lib/keila/empresas/empresas.ex:131-195`); rotas admin (`router.ex:124-131`). **Falta**: o form (`templates/empresa_admin/new.html.heex:17-49`) coleta so 3 campos (nome, cnpj, email_responsavel); telefone/segmento/plano/limites/dominio/DPO existem no schema mas sem UI; **nao ha rota :edit/:update** — `Empresas.atualizar/2` nunca e chamado por controller. |
| 3b | **KYB** | [PARCIAL] | Gate funcional ponta-a-ponta: `pode_enviar?` exige `kyb_status=aprovado` + status em [convidada, ativa], aplicado no worker (`worker.ex:41,67-75`); aprovar/rejeitar com auditoria; grandfathering na migration. **Falta**: nao ha entidade `kyb_verifications` (KYB sao 3 colunas em `empresas`); sem historico, documentos, anexos, prazos ou estado intermediario (`em_analise`); estados em PT-BR (pendente/aprovado/rejeitado), nao pending_kyb/approved/rejected. |
| 4 | **Usuarios / Permissoes (RBAC)** | [PARCIAL] | Infra RBAC granular com CTE recursiva (`auth.ex:318-360`), 4 papeis de empresa criados no boot (`auth.ex:138-205`), convites com token/expiracao/aceite/revogacao (`lib/keila/auth/invitations.ex`), papel do convite de Empresa realmente aplicado (`invite_controller.ex:71`), impersonation auditada. **Falta (critico)**: `Keila.Rbac.can?/3` so e usado em `domain_controller.ex:105` — campanhas/contatos/segmentos/templates/forms/NPS/equipe usam o plug `:authorize` legado que so valida pertencimento; `manage_campaigns`/`manage_contacts`/`view_reports`/`view_compliance_logs` nunca sao checadas em runtime. TeamController hardcoda role "member"->"operator" (`team_controller.ex`, `invite_controller.ex:115-117`); sem UI para o Dono escolher/alterar papel; **default permissivo** (`rbac.ex:28-35`: sem papel = dono). Tambem [AUSENTE]: MFA/2FA, lockout/rate-limit de login, revogacao de sessoes na troca de senha, gate de RBAC na API por papel (`api_authorization_plug.ex` so valida posse do token), auditoria de login/logout/reset. |
| 5 | **Contatos** | [PARCIAL] | Schema com status/data/`double_opt_in_at`/`external_id`/`legal_basis`/`source` (`contact.ex:12-26`); base legal e origem gravadas; double opt-in por HMAC; higiene de descartaveis no import (`email_hygiene.ex`); contacts_events com 10 tipos. **Falta**: campos **telefone** e **ultimo engajamento** nao existem no contato; import nao valida MX (`valid_mx?` existe mas nao e chamado), sem threshold de invalidos, sem dedupe intra-arquivo, sem audit_log da operacao; `delete_contact` faz hard delete sem suprimir nem auditar (email pode ser reimportado); consentimento imutavel so gravado no fluxo de formulario publico (`public_form_controller.ex:342`) — import/API/manual nao gravam `consent_logs`; `policy_version`/`policy_url` nunca preenchidos. |
| 6 | **Listas / Segmentos** | [OK] (infra) | Schema e contexto de segmentos por projeto existem (`contacts_segments`), usados na campanha (`campaign.ex:24-45` segment_id; `_settings_dialog.html.heex`). Enforcement de papel sobre segmentos ausente (ver modulo 4). |
| 7 | **Editor** | [OK] | 4 modos (texto/markdown/blocos/MJML) com WYSIWYG toggle e `do_not_track` (`campaign_settings.ex:6-8`, `builder.ex:182-255`); preview desktop/tablet/mobile via iframe; envio de teste com consumo de credito (`campaign_edit_live.ex:330-345`); blocos JS (button/image/layout/separator/social-icons); MJML+Liquid com brand kit e CSS mobile defensivo; biblioteca global de 13 modelos (`templates/library.ex:13-170`); templates de estilo por projeto. **Parcial**: validacao de links so de formato (sem checagem de quebrados/global); templates so por-projeto, sem template global-de-instancia vs por-empresa. |
| 8 | **Campanhas** | [OK] | Assunto/preview/corpo/segmento/remetente/agendamento (`campaign.ex:24-45`); worker Oban com unique por recipient, rate limit por sender com snooze, backoff/retry transiente (`worker.ex:7-107`); gates inegociaveis no envio (descadastro no corpo, dominio validado, supressao, KYB) em `deliver_campaign` e `deliverable_check` (`mailings.ex:597-633,1128-1150`); lock FOR NO KEY UPDATE; tracking abertura/clique + pixel; cadencia/ondas e campanhas recorrentes (`mailings.ex:644-727,812-870`). **Parcial/Ausente**: status nao persistido (derivado de sent_at/scheduled_for, sem 'pausada'/'em aprovacao', `mailings.ex:978-985`); **sem A/B testing**, **sem fluxo de aprovacao de campanha**, **sem reply_to por campanha** (so no Sender), **sem UTM automatico**. |
| 9 | **Automacoes** | [PARCIAL] | Schema automations/steps/runs (`lib/keila/automations/`), 5 receitas em codigo com `trigger_status` + `delay_days` (`recipes.ex:12-74`), ativar/pausar/excluir, UI em `automations_live.ex`. **Falta (critico)**: `dispatch_run` (`sync_worker.ex:231-253`) **NAO envia email** — apenas valida template e `Logger.info`, marcando run `:sent` sem enviar; espera so em dias; gatilho so por status EVO ou birthday; **sem** branch condicional, acao de tag, webhook, parar-se-converter, metricas por etapa; UI de edicao de fluxo ausente. |
| 10 | **Relatorios / Tracking** | [PARCIAL] | Tracking de abertura/clique com HMAC + anti-bot (`tracking.ex`); contacts_events; stats por campanha em tempo real (enviados/abertos/clicados/falhas/unsub/bounce/complaint + series 24h + top 20 links, `mailings.ex:948-998`). **Falta**: relatorios consolidados por empresa, Dashboard Master, atribuicao de receita, por dominio/segmento, PDF, mapa de calor de cliques. |
| 11 | **Compliance / Seguranca** | [PARCIAL] | Implementado e wired: audit_logs + `Keila.Auditoria` best-effort com IP/UA/ator (`auditoria.ex`, migration `20260623120100`); suppressions empresa+global com indices parciais; consent_logs imutaveis; email_domains + gate SPF/DMARC; data_subject_requests com os 7 tipos do Art.18 (`data_subject/request.ex:11-45`); anonimizacao e export do titular. **Falta**: **UI dos direitos do titular e da supressao** (funcoes `Keila.DataSubject.*`/`Keila.Suppressions.*` sem rota/controller/LiveView); **sem tela de Compliance** para `view_compliance_logs`; login/logout/reset **nao auditados**; **sem MFA admin**, sem lockout, sem criptografia de PII (Cloak), sem HMAC em webhooks de saida; `revoke_consent`/rectification/portability/object sem handler concreto (so anonimizar/exportar). |
| 12 | **Integracoes** | [PARCIAL] | EVO (W12, members via XLSX + prospects via API paginada multi-unidade, `lib/keila/integrations/evo.ex`); API publica `/api/v1` com OpenApiSpex (contacts/campaigns/forms/segments/senders, Bearer); webhook SES de ENTRADA assinado (bounce/complaint/SNS, `ses_webhook_controller.ex`); NPS multi-tenant; ImageKit; IA via OpenRouter (MJML edit/create + brand research). **Falta**: **webhooks de SAIDA assinados** (CRM/WhatsApp/Chatwoot), separacao transacional x marketing, GA/Ads; IA nao faz assunto/score-de-copy/horario ideal (so MJML + brand research). |
| 13 | **Modelo de dados** | [OK] | Esquema completo e migrado em PostgreSQL. Tabelas-chave de governanca/entregabilidade/LGPD: `empresas`, `audit_logs`, `suppressions`, `consent_logs`, `data_subject_requests`, `email_domains`, `invitations`, `roles`/`permissions`/`role_permissions`/`user_group_roles`, `contacts_events`, `nps_*`. **Falta (declarado pendente)**: tabelas de entregabilidade avancada (`dns_checks` historico, `sending_providers`, `feedback_loop_events`, `domain_reputation_scores`, `ip_pools`/`warmup_schedules`, `preference_center_settings`); tabela de `usage`/quota por empresa; `kyb_verifications` dedicada. Billing legado (`accounts`/`credit_transactions`) por grupo, **desacoplado de Empresa**. |

---

---

## 3. Fluxo do Master Admin

O Master Admin do Fluxo (super admin de instância) é o usuário com a permissão `administer_keila` atribuída no root group (`priv/repo/seeds.exs:11-15,44`). Esse atributo é calculado em runtime como `is_admin?` (`lib/keila_web/helpers/auth_session/auth_session_plug.ex:15`) e protege todos os controllers `/admin/*` via plug `authorize`. É o único dos cinco perfis com enforcement totalmente cabeado hoje.

| # | Etapa | Estado ATUAL | Gap vs ALVO |
|---|-------|--------------|-------------|
| 1 | Login Master | [OK] Senha Argon2 + sessão por token sha256 (`auth_controller.ex:183-212`, `user.ex:78-114`) | [AUSENTE] MFA/2FA obrigatório para Master; [AUSENTE] lockout anti brute-force. Crítico para conta root multiempresa. |
| 2 | Cadastra empresa | [OK] `Empresas.cadastrar_empresa` cria Project isolado + Empresa + convite owner, grava `criado_por_id` (`empresas.ex:131-195`); rota `/admin/empresas/new` só `is_admin?` (`router.ex:124-131`) | [PARCIAL] Form (`new.html.heex:17-49`) coleta só nome, cnpj, email_responsavel. Demais campos de governança não têm UI. |
| 3 | Estado pending_kyb | [OK] Empresa nova nasce com `kyb_status=pendente` e `status=convidada`; grandfathering deixa empresas antigas como `aprovado` (`add_kyb_and_plan_to_empresas.exs:16-58`) | [PARCIAL] Estados em PT-BR (`pendente/aprovado/rejeitado`), não `pending_kyb/approved/rejected`; sem estado intermediário `em_analise`, sem anexos/documentos, sem histórico (3 colunas em `empresas`, não entidade `kyb_verifications`). |
| 4 | Gate KYB | [OK] `Empresas.pode_enviar?/1` exige `kyb_status=aprovado` e `status in [convidada, ativa]` (`empresas.ex:93-111`); aplicado por destinatário no worker (`worker.ex:40,67-75`) | Funcional ponta-a-ponta. Projeto sem empresa vinculada (nil) não é bloqueado (comportamento legado). |
| 5 | Define plano/limites | [PARCIAL] `update_changeset` + `Empresas.atualizar/2` cobrem plano/limite_diario/limite_mensal/domínio/DPO (`empresa.ex:100-122`, `empresas.ex:79-84) | [AUSENTE] Sem rota/controller `:edit`/`:update` — `atualizar/2` nunca é chamado por controller (só console). [AUSENTE] `plano` e `limite_diario`/`limite_mensal` são declarativos: nunca lidos/enforced no worker; sem mapa plano→quota; sem tabela `usage_limits`. |
| 6 | Aprova/rejeita KYB | [OK] Workflow no contexto + controller admin com auditoria (`empresas.ex:42-63`, `empresa_admin_controller.ex:82-115`); ações `kyb/aprovar`, `kyb/rejeitar`, `bloquear`, `desbloquear` (`router.ex:124-131`) | [PARCIAL] `aprovar_kyb` sobrescreve estado; sem reabertura formal de KYB rejeitado via UI. |
| 7 | Libera só após KYB + DNS | [OK] Dois gates independentes no envio: KYB/empresa (`worker.ex:40`) por destinatário, e SPF/DMARC do domínio (`mailings.ex:613` em transação + `mailings.ex:1144` em `deliverable_check`) | [PARCIAL] Gate de DNS é progressivo: domínio sem registro em `email_domains` LIBERA por padrão a menos que `REQUIRE_VERIFIED_DOMAIN` esteja ligada (`deliverability.ex:114-127`). Em config padrão, projeto sem domínio cadastrado envia sem prova de SPF/DMARC. Para "liberar só após DNS" como o ALVO exige, ligar a env e cadastrar domínio são pré-requisitos operacionais. |
| 8 | Monitora reputação | [OK] Pausa automática por reputação: spam>0,3%, hard bounce>5%, amostra mínima 500 → bloqueia a EMPRESA + auditoria (`reputation.ex:21-23,46-50,74-107`); disparada de `hard_bounce.ex:15-19` e `complaint.ex:15-19` | [AUSENTE] Dashboard Master agregado (volume/taxas/empresas em risco/domínios pendentes) não existe. [PARCIAL] `breach/1` só cobre spam e hard bounce — não unsubscribe nem soft bounce (`reputation.ex:48-50,112-118`). [AUSENTE] Sem ingestão de reputação do provedor (SES GetReputation / Postmaster). |
| 9 | Impersonation auditada | [OK] `user_admin_controller.ex:127-140` registra auditoria ANTES de trocar sessão (action `user.impersonate`, master como ator), depois `end+start_auth_session` no alvo; rota `router.ex:109` sob `is_admin?` | [AUSENTE] Banner persistente de "modo suporte" na UI durante impersonation não consta na verdade-base — verificar/implementar indicador visual e botão de sair do modo suporte. |

Lacuna estrutural do fluxo Master: login/logout/reset NÃO são auditados apesar do moduledoc da Auditoria (`auth_controller.ex` não chama `Auditoria.registrar_conn`; call sites só em empresa_admin/user_admin/domain/release_tasks/reputation).

---

## 4. Fluxo do Dono da Empresa (owner)

O papel `owner` EXISTE (`@company_roles`, `auth.ex:149-154`, criado idempotentemente no boot via `ensure_company_roles!`) e é REALMENTE atribuído: o convite de empresa nasce com role `"owner"` (`empresas.ex:188`) e, ao aceitar, o `InviteController` chama `Auth.assign_company_role` (`invite_controller.ex:71`). A ressalva central: o papel só altera comportamento em UMA tela hoje.

| # | Etapa | Estado ATUAL | Gap vs ALVO |
|---|-------|--------------|-------------|
| 1 | Aceita convite | [OK] Convite com token randômico 32 bytes, expiração 7 dias, aceite/revogação (`invitation.ex:14-70`, `invitations.ex`, `invite_controller.ex:16-109`) | OK. |
| 2 | Papel aplicado | [OK] `assign_company_role(user.id, project.group_id, "owner")` no aceite (`invite_controller.ex:71`) | [PARCIAL] Enforcement do papel só existe em gestão de domínio. [PARCIAL] Default permissivo do RBAC: usuário sem papel no grupo = tratado como dono (`rbac.ex:28-35`) — fragiliza distinção de perfis. |
| 3 | Configura domínio | [OK] CRUD de domínio por projeto, status pending/verified/failed, flags spf_ok/dmarc_ok/dkim_ok (`domain_controller.ex:24-69`, `email_domain.ex:18-45`, rotas `router.ex:154-157`); única tela que checa RBAC real via `Rbac.can?` para `manage_company_domain` (`domain_controller.ex:105`) | OK; é o único ponto onde o papel owner tem efeito prático. |
| 4 | Valida DNS antes do 1º disparo | [OK] Verifica SPF (v=spf1) + DMARC (`v=DMARC1` com `p=`) via `:inet_res` na criação e sob demanda (`deliverability.ex:69-97,149-160`); gate universal no envio (`mailings.ex:613,1144`) | [PARCIAL] DNS gate é progressivo (libera sem domínio salvo, salvo `REQUIRE_VERIFIED_DOMAIN`); por campanha, não re-checado por destinatário no worker (`worker.ex:38-43` não re-valida DNS). [PARCIAL] DKIM best-effort, não exigido para `verified` (só SPF+DMARC, `deliverability.ex:76`). |
| 5 | Cadastra DPO | [PARCIAL] Campos `dpo_nome`/`dpo_email` existem só no `update_changeset` (`empresa.ex:100-122`) | [AUSENTE] Sem UI e sem rota `:edit`/`:update`; só populável via console. |
| 6 | Convida equipe com papéis | [PARCIAL] `TeamController` hardcoda `role: "member"` → mapeado para `operator` (`invite_controller.ex:113-119`) | [AUSENTE] Sem UI/parâmetro para escolher viewer/compliance; sem tela para alterar role de membro existente (`manage_company_users` definido, sem tela). Nenhuma rota altera `UserGroupRole`. |
| 7 | Opera contatos/campanhas | [OK] Isolamento por pertencimento ao grupo do projeto (`project_plug.ex:13-21`, 404 se não membro) | [AUSENTE] Enforcement por papel ausente: `manage_campaigns/manage_contacts/manage_segments/view_reports` nunca verificados em runtime. Na prática, owner, operator, viewer e compliance têm o MESMO acesso em quase todas as telas (grep confirma zero uso fora de `auth.ex`/`rbac.ex`). |
| 8 | Visão Compliance | [PARCIAL] Role compliance tem `view_compliance_logs`/`view_reports` (`auth.ex:153`); `Auditoria.list_por_projeto/list_recentes` existem (`auditoria.ex:83-106`) | [AUSENTE] Sem controller/rota/template que exponha `audit_logs` ao perfil Compliance; `view_compliance_logs` nunca é checada. |

Lacuna estrutural: trocar a senha NÃO revoga sessões web ativas (`update_user_password` não invalida tokens `web.session`); API key não respeita papel (`api_authorization_plug.ex:9-20` só valida posse do token + pertencimento).

---

## 5. Fluxo de Criação de Campanha

Campanha tem assunto, preview_text, corpo (text/markdown/block/mjml), segmento, remetente e agendamento (`campaign.ex:24-45`). Não há campo de status persistido nem máquina de estados explícita — o status é derivado on-the-fly de `sent_at`/`scheduled_for`/locks (`mailings.ex:978-985`), sem estados `pausada` ou `em aprovação`.

| # | Etapa | Trava/recurso | Estado |
|---|-------|---------------|--------|
| 1 | Rascunho | Editor 4 modos (texto/markdown/blocos/MJML), WYSIWYG, MJML+Liquid com brand kit, CSS mobile defensivo, preview desktop/tablet/mobile, envio de teste (`campaign_settings.ex:6-8`, `builder/mjml.ex:14-95`, `_preview_dialog.html.heex:5-53`, `campaign_edit_live.ex:330-345`) | [OK] |
| 2 | Pré-voo: descadastro no corpo | `campaign_has_unsubscribe?` exige marcador no corpo (`@unsubscribe_markers` inclui unsubscribe_link, /unsubscribe/, descadastr, cancelar inscri) — bloqueia com `:no_unsubscribe_link` em `deliverable_check` (UI) E dentro de `deliver_campaign` (`mailings.ex:609-611,1063-1102,1128-1150`) | [OK] (regra nº 2, defesa em profundidade) |
| 3 | Pré-voo: domínio validado | `sender_domain_liberado?` → `Deliverability.dominio_liberado?`, rollback `:domain_not_verified` (`mailings.ex:613,773-781,1144`) | [OK] mas [PARCIAL] progressivo: domínio sem registro libera salvo `REQUIRE_VERIFIED_DOMAIN`; gate por campanha, não por destinatário |
| 4 | Pré-voo: sem remetente | rollback `:no_sender` (`mailings.ex:600`) | [OK] |
| 5 | Pré-voo: supressão | `ensure_nao_suprimido` no worker por destinatário (local empresa + global), idempotente, sobrevive à recriação do contato (`worker.ex:40,79-86`, `suppressions.ex:67-85`) | [OK] (regra nº 3) |
| 6 | Pré-voo: gate KYB/empresa | `ensure_empresa_pode_enviar` por destinatário (`worker.ex:40,67-75`) | [OK] (regra nº 7) |
| 7 | Score de risco da campanha | — | [AUSENTE] Não há score de risco/spam de copy por IA nem heurística pré-envio (IA só faz MJML edit/create + brand research, não score). |
| 8 | Aprovação se conta nova/alto volume | — | [AUSENTE] Não existe fluxo de aprovação em nível de campanha (editor→revisor→aprovado). A única "aprovação" é o KYB da EMPRESA (gate de tenant), não da campanha. Sem estado `em_aprovacao`. |
| 9 | Agenda/envia | Agendamento (`scheduled_for`), envio em ondas/cadência e recorrente (repeat) — EXTRAS além do requisito (`mailings.ex:644-727,812-870`) | [OK] |
| 10 | Worker enfileira | Oban com unique por `recipient_id`, lock `FOR NO KEY UPDATE` da campanha, bloqueio se `sent_at != nil` (`:already_sent`), rate limit por sender com snooze, retry/backoff de transientes (`worker.ex:7-15,88-107,244-298`, `mailings.ex:597-633,764-771`) | [OK] |
| 11 | Builder injeta headers | List-Unsubscribe + One-Click, Message-ID único, Feedback-ID, X-Auto-Response-Suppress, Auto-Submitted, X-Mailer, Precedence (`builder.ex:361-407`); Reply-To do Sender (`mailer.ex:24,48-53`) | [OK]; [AUSENTE] Return-Path/envelope-from por empresa; [AUSENTE] UTM automático; [AUSENTE] reply_to por campanha (só no Sender) |
| 12 | Tracking | Abertura/clique + pixel HMAC, anti-bot, respeita do_not_track (`builder.ex:410-491`, `tracking.ex`) | [OK]; [AUSENTE] domínio de tracking por empresa (CNAME) — host fixo `KeilaWeb.Endpoint` (`builder.ex:449,465,483`) |
| 13 | Stats | Métricas em tempo real (LiveView 1s até :sent): enviados/abertos/clicados/falhas/unsub/hard_bounce/complaint + séries 24h + top 20 links (`campaign_stats_live.ex`, `mailings.ex:948-998`) | [OK] por campanha; [PARCIAL] sem relatório consolidado por empresa, sem PDF, sem mapa de calor |

---

## 6. Fluxo de Importação de Contatos

O import roda via `Contact.creation_changeset` com `on_conflict` (replace/ignore) contra unique_constraint do banco (`import.ex`). A camada de domínio LGPD está construída, mas o pipeline de import grava base legal hardcoded e não aciona a maioria das validações disponíveis.

| # | Etapa | Estado ATUAL | Gap vs ALVO |
|---|-------|--------------|-------------|
| 1 | Upload CSV | [OK] Import via CSV no contexto (`import.ex`) | OK |
| 2 | Mapeamento de colunas | [OK] Mapeamento de campos no import | OK |
| 3 | Validação de sintaxe | [PARCIAL] `creation_changeset` valida regex básica `^[^@]+@[^@]+$` (`contact.ex:116-126`) — mais fraca que `EmailHygiene` (não exige ponto no domínio) | Endurecer para usar `EmailHygiene.classify/valid_syntax?`. |
| 4 | Validação MX/DNS | [AUSENTE] `EmailHygiene.valid_mx?/1` existe (`email_hygiene.ex:55-74`) mas NUNCA é chamado no import (só `disposable?`) | Cabear `valid_mx?` no pipeline. |
| 5 | Descartáveis/temporários | [OK] `disposable_row?` pula linha sem abortar (`import.ex:141-152`, `@disposable_domains` ~35 domínios) | [PARCIAL] Lista hardcoded curada, não exaustiva. |
| 6 | Spam trap | [AUSENTE] Sem detecção de spam trap (só descartáveis conhecidos) | Implementar. |
| 7 | Threshold de inválidos | [AUSENTE] Sem contagem/percentual; inválidos silenciosamente viram `nil` (`import.ex:138-145`); erro de changeset aborta transação inteira (`raise_import_error!`), sem threshold configurável | Implementar threshold + sinalização. |
| 8 | Base legal + origem obrigatórias | [PARCIAL] `source="import"` e `legal_basis="legitimate_interest"` HARDCODED para toda a importação (`import.ex:136-137`); o usuário NÃO declara base legal | [AUSENTE] Sem campo/validação exigindo declaração de base legal (consent/LIA) por upload nem comprovante (LIA/RIPD). [PARCIAL] Consent.registrar só roda no formulário público (`public_form_controller.ex:342`); import NÃO grava prova imutável em `consent_logs`. |
| 9 | Dedupe | [PARCIAL] Dedupe só contra o banco via unique_constraint + on_conflict | [AUSENTE] Sem dedupe intra-arquivo (sem MapSet de e-mails vistos no próprio CSV). |
| 10 | Auditoria quem/quando/IP | [AUSENTE] `Auditoria.registrar` NÃO é chamado no import (apesar do moduledoc); só grava `contacts_events` tipo `import` por contato (`import.ex:75`), sem audit_log da operação com ator/quantidade/IP | Cabear `Auditoria.registrar_conn`. |
| 11 | Aviso de risco lista comprada/raspada | [AUSENTE] Nenhum aviso/heurística | Implementar gate de UX + termo de responsabilidade. |
| 12 | Eliminação consciente | [PARCIAL] `delete_contact` faz hard delete (`Repo.delete_all`, `contacts.ex:164-197`) sem adicionar à supressão nem auditar — e-mail eliminado pode ser reimportado e voltar a ser contatado (só `anonimizar_contato` suprime, `data_subject.ex:91-97`) | Adicionar supressão + audit no delete. |

Observação de domínio: campos `telefone` e `ultimo_engajamento` pedidos para o contato NÃO existem no schema (`contact.ex` — telefone só em `empresa.ex:38`); `policy_version`/`policy_url` nunca são preenchidos (prova de consentimento sem versão de política).

---

## 7. Fluxo de Configuração de Domínio

O domínio de envio é POR EMPRESA (project_id): schema `email_domains` com status pending/verified/failed, flags `spf_ok`/`dmarc_ok`/`dkim_ok`, `dkim_selector`, `last_checked_at`, `last_error`, unique `[project_id, domain]` (`email_domain.ex:18-45`, migration `20260623130000_create_email_domains.exs`). O gate de envio que consome esse estado vive no CORE (`Keila.Mailings`/`Keila.Deliverability`), não em `extra/keila_cloud` — portanto é UNIVERSAL, não cloud-only.

| # | Etapa | Estado ATUAL | Gap vs ALVO |
|---|-------|--------------|-------------|
| 1 | Cadastra domínio por empresa | [OK] `domain_controller.ex:24-69`, RBAC `manage_company_domain` (`domain_controller.ex:97-114`), rotas `/projects/:id/domains[/verify|/delete]` (`router.ex:154-157`); auditoria de cadastro/verificação/remoção (`domain_controller.ex:30,54,76`) | OK; é por empresa (project_id). |
| 2 | Mostra SPF a publicar | [OK] Coluna SPF na UI (`index.html.heex:9,48-49,64-66`); checa `v=spf1` (`deliverability.ex:149-153`) | UI exibe o formato/local do registro a publicar (`index.html.heex:48-49`: SPF `TXT @ v=spf1`, DMARC `TXT _dmarc v=DMARC1; p=none`); ainda não gera valor copy-paste por domínio nem instrução de DKIM/CNAME. |
| 3 | Mostra DMARC a publicar | [OK] Checa `_dmarc.<dominio>` com `v=DMARC1` + tag `p=` (`deliverability.ex:156-160,179-196`) | Idem item 2 (exibir registro sugerido). |
| 4 | Mostra DKIM a publicar | [PARCIAL] DKIM best-effort por selector; sem `dkim_selector` retorna nil; checagem de TXT `_domainkey` frouxa (aceita `k=` ou `p=`) (`deliverability.ex:166-176`) | [PARCIAL] DKIM NÃO entra no critério de `verified` (só `spf_ok and dmarc_ok`, `deliverability.ex:76`). Domínio é verified sem prova de DKIM. |
| 5 | Mostra Return-Path | [AUSENTE] Sem manipulação de Return-Path/envelope-from/VERP (grep vazio); builder não seta Return-Path; no SES depende do MAIL FROM domain do provedor | Implementar Return-Path por empresa para alinhamento SPF/bounce dedicado. |
| 6 | Mostra CNAME de tracking | [AUSENTE] Domínio de tracking é FIXO (`KeilaWeb.Endpoint`, host único da instância — `builder.ex:449,465,483`, `tracking.ex:60-77`); sem campo de tracking domain por projeto nem CNAME verificável (grep `tracking_domain/custom_domain/cname` vazio) | Tracking NÃO é por empresa hoje. Implementar custom tracking domain + CNAME. |
| 7 | Verifica DNS (job Oban) | [PARCIAL] Verificação on-demand (cadastro + botão verify) via `:inet_res` TXT (`deliverability.ex:69-97,200-213`); `reverificar_todos/0` existe (`deliverability.ex:99-104`) mas NÃO está agendado no crontab do Oban (`config.exs:103-116`) | [AUSENTE] Re-verificação periódica não agendada — status `verified` pode ficar obsoleto (drift de SPF/DMARC) indefinidamente. Agendar `reverificar_todos/0` em cron Oban. |
| 8 | Alinhamento DMARC | [PARCIAL] Valida presença de DMARC válido (`p=`) e SPF, mas não há validação explícita de alinhamento (identifier alignment From↔SPF/DKIM) | Implementar checagem de alinhamento. |
| 9 | Gate de envio universal | [OK] `dominio_liberado?` consumido em `deliver_campaign` (transação, `mailings.ex:613`) e `deliverable_check` (`mailings.ex:1144`) — core, universal | [PARCIAL] Progressivo: domínio sem registro LIBERA por padrão; só bloqueia (`:domain_not_verified`) com EmailDomain cadastrado em status pending/failed, ou sempre quando `REQUIRE_VERIFIED_DOMAIN` ligada (`deliverability.ex:114-127,140-142`). Gate por campanha, não por destinatário no worker. |
| 10 | Score de saúde do domínio | [AUSENTE] Sem score consolidado (DNS check histórico, domain_reputation_scores) — tabelas declaradas pendentes em DESIGN | Implementar score de saúde. |

Resposta direta às duas perguntas-chave: (1) o gate de DNS é UNIVERSAL (vive no core, `mailings.ex:613/1144`, não em cloud), porém PROGRESSIVO/não-estrito por padrão e a nível de campanha; (2) o domínio de tracking NÃO é por empresa — é FIXO, host único da instância, sem CNAME (o único suporte a CNAME, em `extra/keila_cloud/dns.ex`, é cloud-only e não usado pelo gate universal).

---

## 8. Regras de LGPD

| # | Requisito | Status | Evidencia (codigo real) / Gap |
|---|-----------|--------|-------------------------------|
| 8.1 | Origem do contato (form/import/api/manual/integration) | [OK] | Campo `source` no contato; `changeset_from_form` forca `source="form"` (`lib/keila/contacts/schemas/contact.ex:98-99`); import forca `source="import"` (`lib/keila/contacts/import.ex:136-137`). Enum de origem documentado em `contact.ex:20-23`. |
| 8.2 | Data/hora de cadastro | [OK] | Timestamps do schema de contato + `double_opt_in_at` (`contact.ex:12-26`); `occurred_at` no consent_log (`lib/keila/consent/log.ex:14-30`). |
| 8.3 | IP / formulario / integracao / import de origem registrados | [PARCIAL] | IP+user-agent gravados em `consent_logs` somente no fluxo de formulario publico (`lib/keila_web/controllers/public_form_controller.ex:341-350`; `lib/keila/consent.ex:31-64`). Import/API/manual NAO gravam consent_log nem IP de origem — so registram `source` no proprio contato. |
| 8.4 | Base legal (consentimento / legitimo interesse / relacao comercial) | [PARCIAL] | Campo `legal_basis` no contato com valores `consent\|legitimate_interest\|contract` (`contact.ex:20-23`). Form forca `consent` (`contact.ex:98-99`); import forca `legitimate_interest` hardcoded para TODA a planilha (`import.ex:136-137`) sem o operador declarar a base legal. Sem coleta de LIA/RIPD. |
| 8.5 | Prova de consentimento (texto exibido, IP, UA, double opt-in, occurred_at), imutavel | [PARCIAL] | Schema imutavel `consent_logs` (`updated_at: false`) com gravacao best-effort (`lib/keila/consent.ex:31-64`; `lib/keila/consent/log.ex:14-30`; migration `20260623140000_add_legal_basis_and_consent_logs.exs`, `on_delete: nilify_all` preserva a prova). Gap: so e gerado no formulario publico; import/API/manual ficam sem prova imutavel. |
| 8.6 | Politica de privacidade vinculada (versao/URL) + historico de aceite | [PARCIAL] | `consent/log.ex:18-20` tem `policy_version`, `policy_url`, `consent_text`; historico por contato existe (`Consent.historico_por_contato/1`, `consent.ex:67-73`). Gap: `policy_version`/`policy_url` NUNCA sao populados — o form preenche apenas `consent_text` via fine_print (`public_form_controller.ex:353-354`). Prova sem versionamento de politica. |
| 8.7 | Double opt-in | [OK] | Validado por HMAC: `validate_double_opt_in` seta `double_opt_in_at` se HMAC valido (`contact.ex:139-153`); geracao/validacao em `lib/keila/contacts/contacts.ex:395-418`. |
| 8.8 | Descadastro obrigatorio (regra inegociavel) | [OK] | Header `List-Unsubscribe` + One-Click sempre injetado (`lib/keila/mailings/builder.ex:361-365`) e gate de marcador de descadastro no corpo antes de enviar (`lib/keila/mailings/mailings.ex:610,1141`; `campaign_has_unsubscribe?` `1082-1102`). Defesa em profundidade (UI + dentro da transacao de `deliver_campaign`). |
| 8.9 | Lista de supressao por empresa | [OK] | `Suppressions.suprimir` escopo `:project` (`lib/keila/suppressions.ex:28-61`); indice parcial `suppressions_project_email_index` (`migration 20260623120200_create_suppressions.exs`); email `citext`. |
| 8.10 | Lista global de bloqueio (instancia) | [OK] | Escopo `:global` com `project_id` nulo; `bloqueado_globalmente?/1` e `suprimido?/2` consideram local+global (`suppressions.ex:67-85`); indice parcial `suppressions_global_email_index`. |
| 8.11 | Registro de opt-out | [OK] | Unsubscribe gera supressao `reason=unsubscribe`, `source=one_click` (`lib/keila/mailings/recipient_actions/unsubscription.ex:28`) + evento `unsubscribe` em `contacts_events` (`lib/keila/tracking/schemas/event.ex:6-26`). |
| 8.12 | Exclusao / anonimizacao do titular | [PARCIAL] | Anonimizacao completa: remove PII, mantem linha, marca `unsubscribed` e suprime o email original (`lib/keila/data_subject.ex:70-104`). Gap: `delete_contact` (hard delete, `lib/keila/contacts/contacts.ex:164-197`) NAO adiciona a supressao nem audita — email eliminado pode ser reimportado e voltar a ser contatado. |
| 8.13 | Trava de envio p/ descadastrado / bounce permanente | [OK] | Worker consulta supressao por email ANTES de enviar (`lib/keila/mailings/worker.ex:81`, `ensure_nao_suprimido`); supressao automatica em hard bounce / complaint / unsubscribe (`recipient_actions.ex:20-37`; `hard_bounce.ex:33`; `complaint.ex:33`; `unsubscription.ex:28`). Idempotente e por email (sobrevive a recriacao do contato). |
| 8.14 | Auditoria de quem importou / editou / removeu contatos | [AUSENTE] | `Auditoria.registrar` NAO e chamado em `import.ex`, em export, nem em `delete_contact` (apesar do moduledoc de `lib/keila/auditoria.ex` exigir). Import grava apenas `contacts_events` tipo `import` por contato — sem audit_log da operacao com ator/quantidade. Call sites de auditoria so em empresa_admin/user_admin/domain/reputation. |
| 8.15 | Aviso de risco em import sem origem declarada | [AUSENTE] | Import assume `legitimate_interest` hardcoded (`import.ex:136-137`); nao ha tela/parametro que exija declaracao de base legal nem aviso de risco ao importar sem origem comprovada. |
| 8.16 | Bloqueio de lista comprada / raspada | [PARCIAL] | Higiene parcial: deteccao de dominios descartaveis/temporarios pula a linha no import (`lib/keila/contacts/email_hygiene.ex:15-48`; `import.ex:141-152`). Gap: lista hardcoded (~35 dominios), sem deteccao de spam trap, sem threshold de invalidos, sem validacao MX (`valid_mx?` existe mas nao e chamado no import), sem dedupe intra-arquivo. |
| 8.17 | DPO por empresa | [PARCIAL] | Campos `dpo_nome`/`dpo_email` no schema Empresa (`lib/keila/empresas/empresa.ex:53-54`), porem so no `update_changeset` (`empresa.ex:100-122`) — nao estao no cadastro nem no formulario, e nao ha rota `:edit/:update` que chame `Empresas.atualizar/2`. So populavel via console. |
| 8.18 | Retencao / expurgo de dados | [AUSENTE] | Nenhuma politica de retencao/expurgo programada. `reverificar_todos` e outras rotinas nao tem cron; nao ha worker de expurgo por idade/inatividade nem TTL de dados. Tipos de DSR `deletion`/`anonymization` existem mas dependem de acao manual. |
| 8.19 | Incidente -> notificacao a ANPD | [AUSENTE] | Nenhum fluxo de gestao de incidente / notificacao a ANPD no codigo (sem schema, worker, controller ou notificacao). |
| 8.20 | Criptografia de PII em repouso | [AUSENTE] | Sem criptografia de campo (Cloak ausente das deps); PII (email/nome/telefone da Empresa, dados do contato) em texto puro no PostgreSQL. Cloak ausente de `mix.exs` (deps). Existe apenas hashing de tokens (sha256) e Argon2 de senha — nao e criptografia de PII. |
| 8.x (bonus) | Direitos do titular Art.18 (7 tipos) | [PARCIAL] | Schema `data_subject_requests` com os 7 tipos (access, rectification, portability, deletion, anonymization, revoke_consent, object) e status (`lib/keila/data_subject/request.ex:11-45`). So `anonimizar_contato` e `exportar_contato` tem handler concreto (`data_subject.ex:70-134`); `revoke_consent`/`rectification`/`portability`/`object` apenas marcam o DSR como concluido. SEM rota/controller/LiveView — funcoes existem mas nao estao expostas na UI (portal do titular e painel admin pendentes). |

Resumo da secao 8: a camada de DOMINIO LGPD esta solida (consent_logs imutavel, supressao empresa+global por indices parciais, data_subject_requests com Art.18, double opt-in HMAC, trava de supressao no envio). As lacunas concentram-se em (i) cobertura de prova de consentimento fora do formulario, (ii) ausencia de UI para direitos do titular e gestao de supressao, (iii) auditoria de import/export/delete inexistente, (iv) retencao/expurgo, incidente->ANPD e criptografia de PII em repouso ainda nao construidos.

## 9. Regras de Entregabilidade

| # | Requisito | Status | Evidencia (codigo real) / Gap |
|---|-----------|--------|-------------------------------|
| 9.1 | Dominio de envio por empresa | [OK] | Schema/CRUD `email_domains` por `project_id` com status `pending/verified/failed`, unique `[project_id,domain]` (`lib/keila/deliverability/email_domain.ex:18-45`; migration `20260623130000_create_email_domains.exs`). UI/controller protegidos por RBAC `manage_company_domain` (`lib/keila_web/controllers/domain_controller.ex:24-114`; rotas `router.ex:154-157`). |
| 9.2 | SPF | [OK] | `check_spf` via `:inet_res` TXT, exige `v=spf1` (`lib/keila/deliverability.ex:149-153,200-213`); flag `spf_ok` em `email_domains`. |
| 9.3 | DKIM | [PARCIAL] | `check_dkim` best-effort por selector (`deliverability.ex:166-176`). Gap: sem `dkim_selector` retorna nil; DKIM NAO entra no criterio de `verified` (status exige so `spf_ok and dmarc_ok`, `deliverability.ex:76`); checagem TXT de `_domainkey` frouxa (aceita `k=` ou `p=`). Dominio fica `verified` sem prova de DKIM. |
| 9.4 | DMARC + alinhamento | [PARCIAL] | `check_dmarc` valida `_dmarc.<dominio>` com `v=DMARC1` e tag `p=` (`deliverability.ex:156-160,179-196`); flag `dmarc_ok`. Gap: valida existencia/politica do registro DMARC, mas NAO verifica alinhamento real (SPF/DKIM aligned) por mensagem — alinhamento depende do Return-Path/From, e Return-Path nao e controlado (ver 9.5). |
| 9.5 | Return-Path / envelope-from / VERP por empresa | [AUSENTE] | Nenhuma manipulacao de Return-Path/envelope (grep vazio). Builder so seta From/Reply-To (`lib/keila/mailer.ex:24,48-53`); no SES o envelope-from depende do MAIL FROM domain do provedor, nao controlado pelo app. Sem Return-Path dedicado por empresa para alinhamento SPF e bounce processing proprio. |
| 9.6 | Dominio de tracking personalizado por empresa (CNAME) | [AUSENTE] | Dominio de tracking FIXO: clique/abertura/pixel usam `KeilaWeb.Endpoint` (host unico da instancia) — `lib/keila/mailings/builder.ex:449,465,483`; `lib/keila/tracking/tracking.ex:60-77`. Sem campo de tracking domain por projeto nem verificacao CNAME (suporte a CNAME so em `extra/keila_cloud/dns.ex`, cloud-only, nao usado pelo gate universal). |
| 9.7 | Verificacao DNS antes de liberar (gate) | [PARCIAL] | Gate UNIVERSAL no core dentro de `deliver_campaign` (`lib/keila/mailings/mailings.ex:613`, rollback `:domain_not_verified`) e re-checado em `deliverable_check` (`mailings.ex:1144`); `dominio_liberado?/2` (`deliverability.ex:114-127`). Gaps: (a) PROGRESSIVO/nao-estrito — dominio sem registro em `email_domains` LIBERA por padrao a menos que `REQUIRE_VERIFIED_DOMAIN` esteja ligada (`deliverability.ex:140-142`); (b) gate e por CAMPANHA, nao por destinatario no worker (jobs ja enfileirados nao revalidam DNS). |
| 9.7.1 | Re-verificacao periodica de DNS (drift SPF/DMARC) | [PARCIAL] | `reverificar_todos/0` existe (`deliverability.ex:99-104`) mas NAO esta agendada no crontab do Oban (`config/config.exs:103-116`). Verificacao so on-demand (cadastro/botao). Status `verified` pode ficar obsoleto indefinidamente. |
| 9.8 | Score de saude (do dominio/envio) | [PARCIAL] | Existem flags discretas `spf_ok/dmarc_ok/dkim_ok` + `last_checked_at/last_error` por dominio (`email_domain.ex:18-33`) e metricas por campanha (taxas). Gap: nao ha score de saude consolidado (numerico/agregado) por dominio ou empresa; declarado pendente (sem `domain_reputation_scores`). |
| 9.9 | Monitoramento de bounce / spam / unsub | [OK] | Handlers de hard/soft bounce, complaint e unsubscribe marcam recipient, mudam status do contato e gravam supressao (`recipient_actions/hard_bounce.ex:31-34`, `soft_bounce.ex:26-38` [>=3 -> unreachable], `complaint.ex:31-34`, `unsubscription.ex:26-29`); webhook SES (SNS) assinado correlaciona por `messageId` (`lib/keila_web/controllers/ses_webhook_controller.ex:15-78`; `sender_adapters/ses.ex:48-67`). Metricas (enviados/abertos/clicados/bounce/complaint/unsub + series 24h + top 20 links) em `mailings.ex:948-998`. |
| 9.10 | Limite automatico para dominio novo | [AUSENTE] | Rate limit e FIXO por sender/adapter (segundo/minuto/hora) via ExRated (`lib/keila/mailings/rate_limiter.ex:62-118`; `schemas/sender_config.ex:12-14`); nao evolui por idade/novidade do dominio. Sem cota progressiva para dominio recem-cadastrado. Os campos `limite_diario`/`limite_mensal` da Empresa existem mas NUNCA sao aplicados (grep vazio fora de schema/migration). |
| 9.11 | Warmup responsavel (rampa, sem engajamento falso) | [AUSENTE] | Nenhuma implementacao (grep `warmup/ramp/aquecimento` = vazio). Sem agenda de volume crescente, cota diaria progressiva nem limite por idade de sender/dominio. Sem `ip_pools`/`warmup_schedules` (sem migration correspondente). |
| 9.12 | Pausa automatica por bounce/spam/unsub alto | [PARCIAL] | Pausa por reputacao bloqueia a EMPRESA inteira: spam > 0,3%, hard bounce > 5%, amostra minima 500 (`lib/keila/reputation.ex:21-23,46-68,74-107` -> `Keila.Empresas.bloquear` + Auditoria); disparada de `hard_bounce.ex:15-19` e `complaint.ex:15-19`; barra novos envios via gate de empresa no worker (`worker.ex:69-75`). Gap: `breach/1` trata SO spam e hard bounce — NAO ha limiar por unsubscribe (calculado em `reputation.ex:112-118` mas nao usado) nem por soft bounce. |
| 9.13 | Verificacao de emails invalidos | [PARCIAL] | No envio, erro de email invalido marca contato `unreachable` (`worker.ex:228-240`). No cadastro, `Contact.creation_changeset` valida sintaxe basica `^[^@]+@[^@]+$` (`contact.ex:116-126`). Gaps: regex de sintaxe mais fraca que a do EmailHygiene; `valid_mx?`/`valid_syntax?`/`classify` existem (`email_hygiene.ex:38,55-86`) mas NAO sao chamados no import/cadastro (so `disposable?`); sem checagem MX/DNS no pipeline. |
| 9.14 | Prevencao de spam trap / invalido / inativo | [PARCIAL] | Cobertura parcial: dominios descartaveis pulados no import (`email_hygiene.ex:15-48`), supressao automatica de bounce/complaint, hard bounce -> `unreachable`. Gaps: sem deteccao real de spam trap (so descartaveis conhecidos, lista hardcoded ~35), sem campo de ultimo engajamento no contato (`contact.ex` nao tem `last_engagement` — so inferivel via `contacts_events`), sem politica de sunset/inativos. |
| 9.15 | Relatorio de entregabilidade por campanha | [OK] | Stats por campanha em tempo real (LiveView, atualiza ate `:sent`): enviados/abertos/clicados/falhas/unsub/hard_bounce/complaint + series temporais 24h + top 20 links (`lib/keila_web/live/campaign_stats_live.ex`; `mailings.ex:948-998`; `Tracking.get_link_stats`, `tracking.ex:194-203`; rota `:stats` `router.ex:204`). |
| 9.16 | Relatorio de entregabilidade por dominio | [AUSENTE] | Nao ha relatorio agregado por dominio (nem por empresa/segmento, nem dashboard Master). So existe metrica por campanha. Sem tabela `domain_reputation_scores`/`feedback_loop_events`. |
| 9.x (bonus) | Cabecalhos de entregabilidade no builder | [OK] | `List-Unsubscribe` + `List-Unsubscribe-Post` One-Click, Message-ID unico (sha256) por destinatario, Feedback-ID, X-Auto-Response-Suppress, Auto-Submitted, X-Mailer, Precedence (config), MIME-Version (`lib/keila/mailings/builder.ex:361-407`). |
| 9.x (bonus) | Suporte a Configuration Set do SES (FBL/eventos do provedor) | [OK] | `ses_configuration_set` -> `put_provider_option :configuration_set_name` (`sender_adapters/ses.ex:8-15,35-43`; `mailer.ex:25`). Gap relacionado: ingestao de reputacao do provedor (SES GetReputation/Google Postmaster) AUSENTE — reputacao so a partir de metricas internas por campanha. |

Resumo da secao 9: os fundamentos de autenticacao de dominio (SPF/DMARC com gate universal no core), o monitoramento de bounce/complaint/unsub via webhook SES assinado, a supressao automatica, os cabecalhos de entregabilidade e a pausa automatica por reputacao (spam/hard bounce) estao implementados e wired em runtime. As lacunas estruturais sao: DKIM nao exigido para `verified`, gate de DNS progressivo (libera por padrao sem `REQUIRE_VERIFIED_DOMAIN`) e por campanha (nao por destinatario), ausencia de Return-Path/VERP e de dominio de tracking por empresa, ausencia total de warmup/rampa e de limite automatico para dominio novo (incluindo `limite_diario`/`limite_mensal` declarativos e nao enforced), pausa nao cobre unsubscribe/soft bounce, validacao MX nao acionada no import, e ausencia de relatorio de entregabilidade por dominio / dashboard agregado.

---

## 10. Modelo de banco de dados

A plataforma reaproveita o esquema do Keila (Account -> Project -> Group) e o estende com tabelas de governança, entregabilidade e LGPD. A tabela a seguir confronta cada entidade pedida no Prompt Mestre com a **tabela real** existente no banco (ver migrations em `priv/repo/migrations/`).

| Entidade pedida | Tabela real equivalente | Status | Observação (ancorada no código) |
|---|---|---|---|
| tenants / companies | `empresas` | [OK] | `priv/repo/migrations/20260523000000_create_empresas.exs` + `..._20260623120000_add_kyb_and_plan_to_empresas.exs`. 1:1 com `projects` via `project_id`. Schema em `lib/keila/empresas/empresa.ex:30-66`. |
| users | `users` | [OK] | `lib/keila/auth/schemas/user.ex`. Argon2 (linhas 78-114). Sem colunas `failed_attempts`/`locked_at` (lockout [AUSENTE]) nem MFA. |
| roles | `roles` | [OK] | `lib/keila/auth/schemas/role.ex`. Papéis owner/operator/viewer/compliance semeados idempotentemente em `auth.ex:149-154` via `ensure_company_roles!` (seeds.exs:67). |
| permissions | `permissions` | [OK] | `lib/keila/auth/schemas/permission.ex`. 8 permissões de empresa em `auth.ex:138-147`. Junções: `role_permissions`, `user_groups`, `user_group_roles` (CTE recursiva de herança em `auth.ex:318-360`). |
| contacts | `contacts` | [OK] (campos a adicionar — ver abaixo) | `lib/keila/contacts/schemas/contact.ex:12-26`. Já tem `legal_basis`, `source`, `double_opt_in_at`, `external_id`, `status`. |
| contact_custom_fields | `contacts.data` (JsonField embutido) | [PARCIAL] | Não há tabela dedicada de campos custom; valores ficam em coluna `data` (JSONB) no próprio contato (`contact.ex:15`). Sem catálogo/tipagem de campos por empresa. |
| contact_events | `contacts_events` | [OK] | `lib/keila/tracking/schemas/event.ex:6-26` (10 tipos: create/import/subscribe/unsubscribe/double_opt_in/open/click/soft_bounce/hard_bounce/complaint). |
| lists | `contacts_forms` (proxy parcial) | [PARCIAL] | Não há entidade "lista" explícita. A segmentação é por filtro (`contacts_segments`); a noção de origem aproxima-se de `contacts_forms`/`source`. Sem listas estáticas nomeadas. |
| segments | `contacts_segments` | [OK] | Segmentos por filtro dinâmico por projeto. |
| tags | — | [AUSENTE] a criar | Não há tabela `tags` nem ação de tag em automações (`step.ex` só tem order/delay_days/template_slug/subject). Tags são pedidas como gatilho/ação — inexistentes. |
| campaigns | `mailings_campaigns` | [OK] | `lib/keila/mailings/schemas/campaign.ex:24-45`. Sem coluna de status persistido (status derivado de `sent_at`/`scheduled_for`, mailings.ex:978-985). |
| campaign_recipients | `mailings_recipients` | [OK] | Campos de evento: `sent_at`, `soft_bounce_received_at`, `hard_bounce_received_at`, `complaint_received_at`, `unsubscribed_at`, `receipt` (messageId SES). |
| templates | `templates` | [OK] | `lib/keila/templates/schemas/template.ex:5-14` (`belongs_to :project`). Biblioteca global é só código (`library.ex`), não tabela. |
| automations | `automations` | [OK] | `priv/repo/migrations/20260428190000_create_automations.exs`. Disparo real ainda não envia e-mail (`sync_worker.ex:231-253`). |
| automation_steps | `automation_steps` | [OK] | `lib/keila/automations/step.ex`. Sem branch/condição/webhook (pedidos no roadmap). |
| email_domains | `email_domains` | [OK] | `priv/repo/migrations/20260623130000_create_email_domains.exs`. Por `project_id`, status pending/verified/failed, flags spf_ok/dmarc_ok/dkim_ok, `dkim_selector`, `last_checked_at`, `last_error`. |
| dns_checks (histórico) | — | [AUSENTE] a criar | Estado de DNS vive apenas nas colunas de `email_domains` (último resultado). Sem histórico de verificações nem drift. Sem migration correspondente. |
| sending_providers | `mailings_senders` (+ embed `config`) | [PARCIAL] | Provedor/credenciais ficam no embed `mailings_senders.config` (from_email, rate_limit_per_*, ses_configuration_set). Não há tabela própria de provedores com pool/rotação. |
| email_events | `mailings_recipients` (timestamps) + `tracking_links`/`tracking_clicks` + `contacts_events` | [PARCIAL] | Não há tabela única `email_events`. Eventos de entregabilidade são timestamps no recipient; abertura/clique em `tracking_*`; eventos por contato em `contacts_events`. Feedback-loop dedicado [AUSENTE]. |
| suppressions | `suppressions` | [OK] | `priv/repo/migrations/20260623120200_create_suppressions.exs`. Escopo empresa (`project_id`) ou global (`project_id` nulo), índices parciais, email `citext`. |
| consent_logs | `consent_logs` | [OK] | `lib/keila/consent/log.ex:14-30` (imutável, `updated_at: false`). `policy_version`/`policy_url` existem mas nunca populados (gap PARCIAL). |
| audit_logs | `audit_logs` | [OK] | `priv/repo/migrations/20260623120100_create_audit_logs.exs`. action/actor_user_id/actor_email/entity_type/entity_id/project_id/ip/user_agent/metadata (jsonb). |
| billing_plans | `empresas.plano` (coluna) + `accounts`/`credit_transactions` (legado) | [PARCIAL] / [AUSENTE] | Não existe `lib/keila/billing` nem tabela `billing_plans`. `plano` (teste/basico/pro/enterprise) é só armazenado/validado, sem mapeamento plano->quota. Único controle de volume é o ledger legado `credit_transactions` por `account`, desacoplado de `empresas`. |
| usage_limits | `empresas.limite_diario` / `empresas.limite_mensal` (colunas declarativas) | [AUSENTE] a criar (enforcement) | As colunas existem mas **nunca são lidas/aplicadas** no worker/mailings (grep fora de empresa.ex/migrations = vazio). Sem tabela de contadores diários/mensais por empresa. |
| webhooks (saída) | — | [AUSENTE] a criar | Só há webhook de **entrada** (SES em `ses_webhook_controller.ex`) e Paddle (cloud). Nenhum webhook de saída assinado (grep outbound/webhook_url = vazio). Pedido para V2. |

### Campos novos a adicionar em `contacts`

Confronto do schema real (`lib/keila/contacts/schemas/contact.ex:12-26`) com o exigido:

| Campo pedido | Status | Ação |
|---|---|---|
| `legal_basis`, `source`, `double_opt_in_at`, `external_id`, `status`, `data` | [OK] | Já existem (migrations 20260623140000, 20250223090326, 20231210140318). |
| `telefone` / `phone` | [AUSENTE] a criar | Inexistente em `contact.ex` (telefone só em `empresas` e `evo_units`). Adicionar coluna `phone`. |
| `last_engagement` / `ultimo_engajamento` | [AUSENTE] a criar | Não há coluna desnormalizada; engajamento só inferível via `contacts_events`. Adicionar `last_engagement_at` (atualizado por open/click). |

### Campos de governança em `empresas` que existem mas não têm UI nem enforcement

`empresa.ex:30-66` já define `responsavel_nome`, `telefone`, `segmento`, `site`, `observacoes`, `plano`, `limite_diario`, `limite_mensal`, `dominio_principal`, `subdominio_envio`, `dpo_nome`, `dpo_email`, além dos campos KYB (`kyb_status`, `kyb_aprovado_em`, `kyb_aprovado_por_id`, `kyb_motivo_rejeicao`) e `criado_por_id`. Lacunas a fechar (sem migration, são colunas existentes):
- O formulário de cadastro (`new.html.heex:17-49`) coleta apenas 3 campos (nome, cnpj, email_responsavel); `dominio_principal`/`subdominio_envio`/`dpo_*` nem estão na `creation_changeset` (só na `update_changeset`, `empresa.ex:100-122`).
- Não há rota/controller `:edit`/`:update` para `empresas`; `Empresas.atualizar/2` (`empresas.ex:79-84`) nunca é chamado por nenhum controller. Toda governança comercial/DPO só é populável por console.

### Decisão de arquitetura

- **`project_id` é a chave de isolamento e equivale a `company_id` na prática.** A relação `empresas` 1:1 `projects` (via `project_id`) faz do projeto o limite do tenant. Praticamente toda tabela de domínio (`contacts`, `mailings_campaigns`, `templates`, `contacts_segments`, `email_domains`, `suppressions` no escopo empresa, `data_subject_requests`, `nps_*`) carrega `project_id`.
- **Isolamento a nível de aplicação, não RLS.** Não há Row-Level Security no PostgreSQL. O isolamento é garantido por código: `project_plug.ex:13-21` retorna 404 se o usuário não pertence ao grupo do projeto; `projects.ex:111-118` (`get_user_project` via `Auth.user_in_group?`); e na API por `api_authorization_plug.ex:9-20` (token Bearer vinculado a projeto). Consequência: qualquer query que esqueça o filtro `project_id` vaza entre tenants — o banco não oferece rede de proteção.
- **Recomendação:** manter isolamento app-level (consistente com o upstream Keila) e adicionar, como defesa em profundidade, escopos Ecto obrigatórios por `project_id` nos contextos críticos; avaliar RLS apenas para tabelas de maior risco (`contacts`, `consent_logs`, `audit_logs`) num momento posterior. A supressão usa modelo híbrido proposital: `project_id` nulo = global (cross-tenant), por design (`suppressions.ex:67-75`).

## 11. Permissões por perfil

Os 5 perfis existem e têm permissões mapeadas, **mas o enforcement em runtime é quase inexistente**. Esta matriz declara o comportamento-alvo (coluna por perfil) e, na coluna "Estado real do RBAC", o que de fato é checado hoje.

Legenda: P = permitido (alvo) · L = leitura · — = negado (alvo).

| Recurso | Master Admin Fluxo | Dono (owner) | Operador | Visualizador | Compliance/Suporte | Estado real do RBAC (ancorado em arquivo) |
|---|---|---|---|---|---|---|
| Empresas (cadastro/KYB/bloqueio) | P | — | — | — | — | [OK] Só Master. Plug `authorize` exige `is_admin?` em `empresa_admin_controller.ex` (rotas router.ex:124-131). `is_admin?` = `administer_keila` no root group (auth_session_plug.ex:15). |
| Usuários da empresa (convidar/papel) | P | P | — | — | — | [AUSENTE] enforcement. `manage_company_users` definido (auth.ex:139) mas nunca checado. `team_controller.ex` hardcoda convite como `member`->`operator` (invite_controller.ex:115-117); sem UI para escolher/alterar papel. |
| Domínio de envio (SPF/DMARC) | P | P | P? | — | — | [OK] (único ponto real) `Keila.Rbac.can?/3` com `manage_company_domain` em `domain_controller.ex:105`. É o **único** uso de `can?/3` no app (rbac.ex:27-37). |
| Plano / billing | P | P (alvo) | — | — | — | [AUSENTE] enforcement. `manage_company_billing` definido (auth.ex:141) e nunca checado. Sem UI de plano; ledger legado por Account desacoplado da empresa. |
| Contatos (criar/editar/excluir) | P | P | P | L | L | [AUSENTE] enforcement. `manage_contacts` definido (auth.ex:143) e nunca verificado. Hoje viewer/compliance conseguem criar/editar (plug `:authorize` legado só valida pertencimento). |
| Import / Export de contatos | P | P | P | — | L (export p/ compliance) | [AUSENTE] enforcement + [AUSENTE] auditoria. Import/export não checam papel nem chamam `Auditoria.registrar` (gap confirmado em import.ex). |
| Listas / Segmentos | P | P | P | L | L | [AUSENTE] enforcement. `manage_segments` definido (auth.ex:144) e nunca verificado. |
| Campanhas (criar/enviar) | P | P | P | L | — | [AUSENTE] enforcement. `manage_campaigns` (auth.ex:142) nunca checado em `campaign_edit_live.ex`; viewer pode enviar hoje. |
| Automações | P | P | P | L | — | [AUSENTE] enforcement (mesma permissão `manage_campaigns`). Disparo real ainda não implementado (sync_worker.ex:231-253). |
| Relatórios / métricas | P | P | P | L | L | [AUSENTE] enforcement. `view_reports` (auth.ex:145) presente em todos os papéis mas nunca checado; `campaign_stats_live.ex` aberto a qualquer membro. |
| Logs / Auditoria | P | P (alvo) | — | — | P | [PARCIAL]/[AUSENTE]. `view_compliance_logs` (auth.ex:146) definido para owner/compliance, mas **não há controller/rota/tela** que exponha `audit_logs` (funções `Auditoria.list_por_projeto/list_recentes` existem, ex.84-106). Compliance não tem painel. |
| Consent / opt-out (LGPD/DSR/supressão) | P | P (alvo) | — | — | P (alvo) | [AUSENTE] UI. Backend completo (`Keila.DataSubject`, `Keila.Suppressions`) sem rota/controller/LiveView (grep router = vazio). Nenhum perfil acessa via interface hoje. |
| Impersonation (modo suporte) | P | — | — | — | — | [OK] Só Master, auditado antes de trocar sessão (`user_admin_controller.ex:127-140`, rota router.ex:109, plug exige `is_admin?`). |

### Diagnóstico do RBAC (o que existe, o que falta)

- **Definição (semeadura): [OK].** Os 4 papéis de empresa e as 8 permissões existem e são criados idempotentemente no boot via `ensure_company_roles!` (`auth.ex:149-180`, chamado em `seeds.exs:67`). Master via `administer_keila` (`seeds.exs:11-15,44`). Não falta semear nada.
- **Atribuição do papel: [PARCIAL].** O convite de **Empresa** nasce como `owner` e é realmente aplicado ao aceitar (`empresas.ex:188` -> `invite_controller.ex:71` `assign_company_role`). O convite de **equipe** sempre cai em `operator` (hardcode `member` em `team_controller.ex` + `papel_do_convite` em invite_controller.ex:113-119); não há UI para escolher viewer/compliance nem para alterar papel de um membro existente.
- **Enforcement: [AUSENTE] (crítico).** O único módulo que consulta papel — `Keila.Rbac.can?/3` (`rbac.ex:27-37`) — está cabeado em **um único ponto**: `domain_controller.ex:105` (`manage_company_domain`). Todos os demais controllers/LiveViews de projeto usam o plug `:authorize` legado, que só confirma pertencimento ao projeto. Resultado prático: **operator, viewer e compliance têm o mesmo acesso de um owner** em campanhas, contatos, segmentos, templates, forms, NPS e equipe. As permissões `manage_campaigns`/`manage_contacts`/`manage_segments`/`view_reports`/`view_compliance_logs`/`manage_company_users`/`manage_company_billing` nunca são verificadas em runtime.
- **Default permissivo: [PARCIAL] (risco).** `can?/3` retorna `true` quando o usuário não tem **nenhum** papel de empresa no grupo (`rbac.ex:28-35`, tratado como dono). Usuários legados (ex.: o Master que cria a empresa, membros adicionados via `add_user_to_group` sem papel) têm acesso total. Isso fragiliza viewer/compliance se o papel não for aplicado consistentemente.
- **Lacunas adjacentes ao RBAC:** sem MFA/2FA (grep mfa/totp/webauthn = 0); sem lockout/rate-limit de login (User não tem `failed_attempts`/`locked_at`); login/logout/reset não auditados apesar do moduledoc (`auth_controller.ex` não chama `Auditoria.registrar_conn`); troca de senha não revoga sessões web ativas; API Bearer não respeita papel (`api_authorization_plug.ex` só valida posse do token + projeto, ex.9-20).

### O que falta ativar/aplicar (ordem de prioridade)

1. **Cabear `Keila.Rbac.can?/3`** (ou um plug equivalente) nos controllers/LiveViews de campanha, contato, segmento, template, form, NPS e equipe — usando as permissões já semeadas. Sem isso, os 5 perfis são privilege-equivalent.
2. **Tornar o default não-permissivo** para usuários com papel atribuído e migrar usuários legados (atribuir `owner` explícito a quem criou/é dono da empresa) — endurecer `rbac.ex:30-34`.
3. **UI de equipe**: seleção de papel no convite e tela de gestão/alteração de papel por membro (`team_controller.ex`), checando `manage_company_users`.
4. **Painel de Compliance** expondo `audit_logs` (ligar `Auditoria.list_por_projeto` a rota/LiveView, gate `view_compliance_logs`) e **portal/painel de DSR e supressão** (ligar `Keila.DataSubject`/`Keila.Suppressions` à UI).
5. **Gate de RBAC na API** por papel (`api_authorization_plug.ex`).
6. **Endurecimento de autenticação** (MFA para Master/Dono, lockout, auditoria de login, revogação de sessões na troca de senha).

Arquivos-chave para essas mudanças: `/home/cleiton-sampaio/Documentos/Projeto/email/lib/keila/rbac.ex`, `/home/cleiton-sampaio/Documentos/Projeto/email/lib/keila/auth/auth.ex`, `/home/cleiton-sampaio/Documentos/Projeto/email/lib/keila_web/controllers/team_controller.ex`, `/home/cleiton-sampaio/Documentos/Projeto/email/lib/keila_web/controllers/invite_controller.ex`, `/home/cleiton-sampaio/Documentos/Projeto/email/lib/keila_web/controllers/domain_controller.ex`, `/home/cleiton-sampaio/Documentos/Projeto/email/lib/keila_web/api/plugs/api_authorization_plug.ex`, `/home/cleiton-sampaio/Documentos/Projeto/email/lib/keila/auditoria.ex`, `/home/cleiton-sampaio/Documentos/Projeto/email/lib/keila/data_subject.ex`, `/home/cleiton-sampaio/Documentos/Projeto/email/lib/keila/suppressions.ex`, `/home/cleiton-sampaio/Documentos/Projeto/email/lib/keila/contacts/schemas/contact.ex`, `/home/cleiton-sampaio/Documentos/Projeto/email/lib/keila/empresas/empresa.ex`.

---

## 12. Roadmap MVP, versão 2 e versão 3

**Princípio orientador:** governança, entregabilidade e LGPD são FUNDAÇÃO — entram no MVP, não no V2. O MVP fecha as regras inegociáveis de disparo (descadastro no corpo, supressão por e-mail, gate de KYB da empresa, validação de DNS, base legal). O V2 entrega relacionamento e direitos do titular operacionalizados. O V3 entrega inteligência e escala. A coluna "Hoje" reflete o estado real conforme a verdade-base.

### 12.1 MVP — Fechar as regras inegociáveis (fundação)

| # | Item | Hoje | Âncora no código |
|---|------|------|------------------|
| 1 | Multi-tenant por `project_id` com isolamento por pertencimento a grupo | [OK] | `lib/keila_web/helpers/project/project_plug.ex:13-21`; `lib/keila/projects.ex:111-118` |
| 2 | Autenticação por senha (Argon2) + sessão por token hash sha256 com expiração | [OK] | `lib/keila/auth/schemas/user.ex:78-114`; `lib/keila/auth/token.ex:48-73` |
| 3 | Tenant Empresa com CNPJ validado (dígitos verificadores) e status operacional | [OK] | `lib/keila/empresas/empresa.ex:140-184`; `lib/keila/empresas/empresas.ex:131-195` |
| 4 | KYB como gate de envio (regra nº 7): só dispara com `kyb_status=aprovado` e status em `[convidada, ativa]` | [OK] | `lib/keila/empresas/empresas.ex:93-111`; `lib/keila/mailings/worker.ex:41,67-75` |
| 5 | Workflow KYB aprovar/rejeitar pelo Master com auditoria | [OK] | `lib/keila/empresas/empresas.ex:42-63`; `lib/keila_web/controllers/empresa_admin_controller.ex:82-115` |
| 6 | Enforce de descadastro no corpo antes de enviar (regra nº 2) | [OK] | `lib/keila/mailings/mailings.ex:610,1141,1063-1102` |
| 7 | Cabeçalho `List-Unsubscribe` + One-Click sempre injetado; link HMAC | [OK] | `lib/keila/mailings/builder.ex:361-365`; `lib/keila/mailings/mailings.ex:1155-1180` |
| 8 | Gate de DNS (SPF+DMARC do domínio do `from_email`) no `deliver_campaign` | [PARCIAL] | `lib/keila/mailings/mailings.ex:613,773-781`; `lib/keila/deliverability.ex:114-127` — **progressivo/não-estrito**: domínio sem registro LIBERA por padrão, salvo `REQUIRE_VERIFIED_DOMAIN` |
| 9 | Verificação própria de DNS (TXT via `:inet_res`) + schema `email_domains` por projeto | [OK] | `lib/keila/deliverability.ex:69-97,200-213`; `lib/keila/deliverability/email_domain.ex:18-45` |
| 10 | Supressão por e-mail (escopo empresa + global), travada no envio, sobrevive a recriação | [OK] | `lib/keila/suppressions.ex:28-85`; `lib/keila/mailings/worker.ex:81` |
| 11 | Supressão automática em hard bounce / complaint / unsubscribe | [OK] | `lib/keila/mailings/recipient_actions.ex:20-37` e handlers |
| 12 | Webhook SES (SNS) assinado: Permanent→hard, Transient→soft, complaint | [OK] | `lib/keila_web/controllers/ses_webhook_controller.ex:15-78`; `lib/keila/mailings/sender_adapters/ses.ex:48-67` |
| 13 | Pausa automática por reputação (spam>0,3%, hard bounce>5%, amostra ≥500) bloqueando a empresa | [PARCIAL] | `lib/keila/reputation.ex:21-23,46-107` — cobre spam e hard bounce; **não cobre unsubscribe nem soft bounce** |
| 14 | Base legal + origem por contato (consent / legitimate_interest) | [OK] | `lib/keila/contacts/schemas/contact.ex:12-26,98-99`; `lib/keila/contacts/import.ex:136-137` |
| 15 | `consent_logs` imutável (texto, IP, UA, double opt-in) no fluxo de formulário | [PARCIAL] | `lib/keila/consent.ex:31-64`; wired só em `public_form_controller.ex:341-350` — **import/API/manual não gravam prova** |
| 16 | Double opt-in validado por HMAC | [OK] | `lib/keila/contacts/schemas/contact.ex:139-153`; `lib/keila/contacts/contacts.ex:395-418` |
| 17 | `audit_logs` best-effort com ator/IP/UA/metadata em ações críticas | [OK] | `lib/keila/auditoria.ex:47-81`; call sites em empresa_admin/user_admin/domain/reputation |
| 18 | Impersonation do Master auditada antes de trocar sessão | [OK] | `lib/keila_web/controllers/user_admin_controller.ex:127-140` |
| 19 | Master Admin via `administer_keila` no root group; `/admin/*` protegido | [OK] | `priv/repo/seeds.exs:11-15,44`; `lib/keila_web/helpers/auth_session/auth_session_plug.ex:15` |
| 20 | 4 papéis de empresa (owner/operator/viewer/compliance) semeados no boot | [OK] | `lib/keila/auth/auth.ex:138-205`; `priv/repo/seeds.exs:67` |
| 21 | **Enforcement RBAC dos 4 papéis em todas as telas** | [PARCIAL] | `lib/keila/rbac.ex:27-37` cabeado SÓ em `domain_controller.ex:105` — operator/viewer/compliance ≈ owner nas demais telas |
| 22 | Worker Oban com unique por recipient, rate limit por sender, retry transiente | [OK] | `lib/keila/mailings/worker.ex:7-15,88-107,244-298` |
| 23 | Editor multi-modo (texto/markdown/blocos/MJML) + preview responsivo + envio de teste | [OK] | `lib/keila/mailings/schemas/campaign_settings.ex:6-8`; `lib/keila_web/live/campaign_edit_live.ex:330-345` |
| 24 | Stats por campanha em tempo real (enviados/abertos/clicados/bounce/complaint/unsub) | [OK] | `lib/keila/mailings/mailings.ex:948-998`; `lib/keila_web/live/campaign_stats_live.ex` |

**Itens do MVP ainda em aberto (devem ser concluídos antes de declarar a fundação fechada):** #8 (tornar o gate de DNS estrito quando houver domínio cadastrado é OK, mas o default permissivo deixa projetos sem domínio enviando sem validação), #15 (prova de consentimento ausente em import/API/manual), e sobretudo **#21 (RBAC definido mas não aplicado)** — hoje viewer/compliance criam e editam campanhas/contatos/segmentos, configurando privilege-equivalence entre perfis.

### 12.2 Versão 2 — Relacionamento e direitos do titular

| # | Item | Hoje | Âncora no código |
|---|------|------|------------------|
| 1 | Portal/painel de Direitos do Titular (Art. 18) — backend pronto, **sem UI** | [PARCIAL] | `lib/keila/data_subject.ex:19-134` (criar/listar/concluir/rejeitar/exportar/anonimizar); sem rota/controller |
| 2 | Handlers concretos para `revoke_consent`/`rectification`/`portability`/`object` | [AUSENTE] | só `anonimizar_contato` e `exportar_contato` existem; demais tipos só marcam DSR como completed |
| 3 | Gestão da lista de supressão pela empresa (visualizar/exportar/remover) | [PARCIAL] | `lib/keila/suppressions.ex:89-128` existe; sem rota/UI |
| 4 | Tela de Compliance para ver `audit_logs` (`view_compliance_logs`) | [PARCIAL] | `lib/keila/auditoria.ex:83-106` (list_por_projeto/recentes); sem controller/view |
| 5 | UI do Dono para atribuir/alterar papéis e escolher papel no convite de equipe | [AUSENTE] | `team_controller.ex` hardcoda `member`→`operator`; sem rota de alteração de role |
| 6 | Hard delete que adiciona à supressão e gera audit log | [PARCIAL] | `lib/keila/contacts/contacts.ex:164-197` faz `delete_all` sem suprimir nem auditar |
| 7 | Auditoria de login/logout/reset e de import/export de contatos | [PARCIAL]/[AUSENTE] | moduledoc promete; `auth_controller.ex` e `import.ex` não chamam `Auditoria.registrar_conn` |
| 8 | `policy_version`/`policy_url` na prova de consentimento | [PARCIAL] | `lib/keila/consent/log.ex:18-20` tem os campos; nunca populados |
| 9 | Dashboard agregado da Empresa (base ativa, origens, saúde, taxa média) | [PARCIAL] | só há stats por campanha (`campaign_stats_live.ex`) |
| 10 | Dashboard Master (volume/taxas/empresas em risco/domínios pendentes) | [AUSENTE] | só admin de instância/empresas/usuários, sem agregação |
| 11 | Relatórios consolidados por empresa/domínio/segmento + PDF | [PARCIAL]/[AUSENTE] | só relatório por campanha; sem PDF nem mapa de calor |
| 12 | Automações via UI: branch condicional, ação de tag, parar-se-converter, métricas por etapa | [PARCIAL]/[AUSENTE] | receitas hardcoded `recipes.ex`; step só `delay_days`+template |
| 13 | **Envio real das automações** (hoje só loga) | [AUSENTE] | `automations/workers/sync_worker.ex:231-253` — `dispatch_run` não envia, marca `:sent` |
| 14 | Enforcement de limites por empresa (`limite_diario`/`limite_mensal`) + tracking de uso | [AUSENTE] | campos declarativos; nunca lidos no worker; sem tabela `usage` |
| 15 | Vínculo plano→quota/créditos e edição/governança da empresa pelo Master (rota `:edit`/`:update`) | [AUSENTE] | `update_changeset` e `atualizar/2` existem mas sem rota/controller |
| 16 | Formulário de cadastro de empresa completo (hoje só nome/cnpj/email) | [PARCIAL] | `new.html.heex:17-49` coleta 3 campos; demais só via console |
| 17 | A/B testing de campanha e fluxo de aprovação de campanha | [AUSENTE] | sem variantes/seleção de vencedor; só KYB de empresa |
| 18 | Re-verificação periódica de DNS agendada (drift SPF/DMARC) | [PARCIAL] | `reverificar_todos/0` existe (`deliverability.ex:99-104`) mas **não agendada no crontab Oban** |
| 19 | Webhooks de SAÍDA assinados (HMAC): campanha enviada / bounce alto / novo contato | [AUSENTE] | só webhook de entrada (SES) e Paddle cloud |
| 20 | Pausa automática por taxa de descadastro e por soft bounce | [PARCIAL] | `reputation.ex:48-50` só spam+hard bounce; `unsubscribe_rate` calculado mas não usado |
| 21 | Preference center / central de preferências | [AUSENTE] | sem `preference_center_settings` |
| 22 | UTM tagging automático e reply-to por campanha | [AUSENTE] | sem geração de UTM; reply-to só no Sender |

### 12.3 Versão 3 — Inteligência e escala

| # | Item | Hoje | Âncora no código |
|---|------|------|------------------|
| 1 | IA: geração/edição de MJML em pt-BR com brand kit | [OK] | `lib/keila/ai/email_editor.ex`; `lib/keila/ai/brand_research.ex` |
| 2 | IA: sugestão de assunto, score de copy/spam, horário ideal de envio | [AUSENTE] | subject default é texto fixo (`ai_controller.ex:43`) |
| 3 | Warmup / rampa de aquecimento por IP/domínio/dia | [AUSENTE] | zero código (grep warmup/ramp = vazio); rate limit é fixo |
| 4 | Return-Path / envelope-from / VERP por empresa | [AUSENTE] | builder não seta Return-Path |
| 5 | Domínio de tracking por empresa via CNAME (custom tracking domain) | [AUSENTE] | tracking fixo em `KeilaWeb.Endpoint` (`builder.ex:449,465,483`) |
| 6 | Verificação ativa de identidade SES (DKIM CNAMEs) no core; generalizar `KeilaCloud.DNS` (CNAME) | [AUSENTE] | `extra/keila_cloud/dns.ex:11-21` é cloud-only, não usado no gate universal |
| 7 | Monitoramento contínuo de reputação do provedor (SES GetReputation, Google Postmaster) | [AUSENTE] | reputação só de métricas internas por campanha |
| 8 | MFA/2FA (TOTP/WebAuthn) para Master e Donos | [AUSENTE] | sem vestígio (grep mfa/totp/webauthn = 0) |
| 9 | Lockout / rate-limit anti brute-force no login | [AUSENTE] | `post_login` sem contagem/bloqueio |
| 10 | Criptografia de PII em repouso (Cloak) | [AUSENTE] | Cloak ausente de `mix.exs` |
| 11 | Tabelas de entregabilidade avançada (dns_checks histórico, feedback_loop_events, domain_reputation_scores, ip_pools/warmup_schedules) | [AUSENTE] | DESIGN seção 111 |
| 12 | Omnichannel: WhatsApp/SMS, CRM, separação transacional × marketing, GA/Ads | [AUSENTE] | integrações atuais: EVO, API, SES entrada, NPS, ImageKit |
| 13 | BIMI / ARC | [AUSENTE] | roadmap V3 |
| 14 | Gate de RBAC na API (Bearer) por papel | [AUSENTE] | `api_authorization_plug.ex:9-20` só valida posse do token + projeto |

## 13. Checklist técnico

Itens acionáveis de engenharia. `[OK]` = já implementado conforme verdade-base; `[ ]` = pendente.

### 13.1 Migrations e esquema

- [OK] `audit_logs` (`priv/repo/migrations/20260623120100_create_audit_logs.exs`)
- [OK] `suppressions` com índices parciais empresa/global (`20260623120200_create_suppressions.exs`)
- [OK] `consent_logs` + `legal_basis`/`source` em contacts (`20260623140000_add_legal_basis_and_consent_logs.exs`)
- [OK] `data_subject_requests` (`20260623150000_create_data_subject_requests.exs`)
- [OK] `email_domains` por `project_id` (`20260623130000_create_email_domains.exs`)
- [OK] `empresas` + KYB/plano/domínio/DPO com grandfathering (`20260523000000` + `20260623120000_add_kyb_and_plan_to_empresas.exs`)
- [OK] `invitations` (`20260428200000_create_invitations.exs`)
- [ ] **Tabela de tracking de uso por empresa** (`usage_limits` ou contadores diário/mensal) — inexistente; `limite_diario`/`limite_mensal` sem contraparte
- [ ] **Campos `telefone` e `ultimo_engajamento` no contato** — `contact.ex` não possui (telefone só em Empresa)
- [ ] **Coluna `status` persistido na campanha** + máquina de estados — hoje derivado de `sent_at`/`scheduled_for` (`mailings.ex:978-985`)
- [ ] Tabelas de entregabilidade avançada (dns_checks, feedback_loop_events, domain_reputation_scores, ip_pools/warmup_schedules, preference_center_settings)

### 13.2 RBAC e papéis

- [OK] Semear os 4 papéis de empresa idempotentemente no boot (`ensure_company_roles!`, `auth.ex:138-205`, `seeds.exs:67`)
- [ ] **Cabear `Keila.Rbac.can?/3` (ou plug equivalente) nos controllers de campaign/contact/segment/template/form/nps/team** — hoje só em `domain_controller.ex:105`; usar `manage_campaigns`/`manage_contacts`/`manage_segments`/`view_reports`/`view_compliance_logs`
- [ ] **Corrigir default permissivo do RBAC** (`rbac.ex:28-35`: usuário sem papel = dono) — risco a viewer/compliance
- [ ] Parametrizar papel no convite de equipe (`team_controller.ex` hardcoda `member`→`operator`; permitir viewer/compliance)
- [ ] Rota/UI para alterar `UserGroupRole` de um membro existente
- [ ] Gate de RBAC por papel na API Bearer (`api_authorization_plug.ex:9-20`)

### 13.3 Gate de envio e entregabilidade

- [OK] Gate de KYB/empresa por destinatário no worker (`worker.ex:41,67-75`)
- [OK] Gate de supressão por destinatário no worker (`worker.ex:81`)
- [OK] Gate de descadastro no corpo + domínio no `deliver_campaign` (`mailings.ex:610,613`)
- [ ] **Tornar o gate de DNS estrito por padrão** (ou pelo menos exigir domínio cadastrado) — hoje domínio sem registro libera (`deliverability.ex:114-127,140-142`)
- [ ] **Re-checar domínio por destinatário no worker** — gate de DNS é só a nível de campanha; jobs enfileirados não revalidam (`worker.ex:38-43`)
- [ ] Exigir DKIM para status `verified` — hoje `verified = spf_ok and dmarc_ok` (`deliverability.ex:76`); DKIM best-effort (`:166-176`)
- [ ] **Generalizar `extra/keila_cloud/dns.ex` (suporte CNAME) e usá-lo no gate universal** — hoje o core faz só TXT próprio; CNAME não verificado
- [ ] Domínio de tracking por empresa via CNAME — hoje fixo em `KeilaWeb.Endpoint` (`builder.ex:449,465,483`)
- [ ] Return-Path/envelope-from por empresa

### 13.4 Jobs Oban (agendamento)

- [OK] Worker de envio com unique/rate limit/retry (`mailings/worker.ex`)
- [ ] **Agendar `Keila.Deliverability.reverificar_todos/0` no crontab Oban** (`config/config.exs:103-116`) — função existe (`deliverability.ex:99-104`), não agendada
- [ ] **Cron de avaliação de reputação/score periódica** (hoje só reativa a webhook de hard_bounce/complaint)
- [ ] Cron de pausa/expurgo e de tracking de uso diário/mensal por empresa
- [ ] **Implementar envio real em `dispatch_run`** (`automations/workers/sync_worker.ex:231-253` apenas loga e marca `:sent`)

### 13.5 Importação e higiene

- [OK] Pular domínios descartáveis no import (`email_hygiene.ex:43-48`; `import.ex:141-152`)
- [ ] **Invocar `EmailHygiene.valid_mx?/valid_syntax?` no pipeline de import** — existem mas não chamados (`email_hygiene.ex:55-74`)
- [ ] **Threshold configurável de inválidos** no import (abortar/sinalizar acima de %) — inexistente
- [ ] **Dedupe intra-arquivo CSV** (MapSet de e-mails) — hoje só contra o banco via `on_conflict`
- [ ] Permitir o importador **declarar a base legal** (consent/LIA) — hoje hardcode `legitimate_interest` (`import.ex:136-137`)
- [ ] Gravar `consent_logs` (+`policy_version`/`policy_url`) em import/API/manual
- [ ] Auditar a operação de import/export (ator+quantidade) — hoje só `contacts_events` por contato

### 13.6 Direitos do titular e supressão (web)

- [ ] Rota/controller/LiveView para DSR (`Keila.DataSubject.*` está completo, sem UI)
- [ ] Handlers concretos para `revoke_consent`/`rectification`/`portability`/`object`
- [ ] UI de gestão de supressão pela empresa (`Suppressions.list_por_projeto/remover` existem)
- [ ] `delete_contact` deve suprimir o e-mail e auditar (`contacts.ex:164-197`)

### 13.7 Testes dos gates

- [OK] Testes de domínio para consent/suppressions/data_subject/email_hygiene/import (`test/keila/...`)
- [ ] **Testes de integração web dos gates inegociáveis**: descadastro no corpo, supressão no worker, KYB no worker, gate de DNS
- [ ] **Testes cross-tenant** de isolamento por `project_id`
- [ ] Testes de enforcement RBAC por papel (após cabeamento)

## 14. Checklist de segurança

Estado real conforme verdade-base.

| Controle | Estado | Evidência / lacuna |
|----------|--------|--------------------|
| Hash de senha forte (Argon2 + `no_user_verify` anti-timing) | [OK] | `lib/keila/auth/schemas/user.ex:78-114` |
| Tokens de sessão/auth armazenados como hash sha256 (não plaintext) com expiração | [OK] | `lib/keila/auth/token.ex:48-73` |
| CSRF (`protect_from_forgery`) + secure browser headers | [OK] | pipeline browser (router) |
| **MFA/2FA para Master e Donos** | [AUSENTE] | grep mfa/totp/webauthn = 0; única dep de auth é `argon2_elixir` — **crítico** num SaaS multiempresa |
| **Lockout + rate-limit de login (anti brute-force)** | [AUSENTE] | `post_login` sem `failed_attempts`/`locked_at`; rate limiter existente é de envio, não de login |
| Auditoria de impersonation (antes de trocar sessão) | [OK] | `user_admin_controller.ex:127-140` |
| **Banner/aviso visível de modo impersonation** | [AUSENTE] | não há indicação na UI de que o Master está impersonando |
| Auditoria de login/logout/reset | [PARCIAL] | moduledoc promete; `auth_controller.ex` não chama `Auditoria.registrar_conn` |
| Revogação de sessões ao trocar senha / logout forçado | [AUSENTE] | `update_user_password` não invalida tokens `web.session` |
| **Criptografia de PII em repouso (Cloak)** | [AUSENTE] | declarado pendente; e-mails/dados em texto claro |
| HMAC na validação do webhook de ENTRADA (SES/SNS) | [OK] | `ses_webhook_controller.ex:50-56`; `ses.ex:48-67` |
| **HMAC em todos os webhooks (inclui SAÍDA)** | [AUSENTE] | webhooks de saída inexistentes |
| HMAC em links de descadastro e double opt-in | [OK] | `mailings.ex:1155-1180`; `contacts.ex:395-418` |
| Tracking com HMAC-SHA256 + filtro anti-bot | [OK] | `lib/keila/tracking/tracking.ex` (create_hmac/is_bot) |
| Isolamento multi-tenant por `project_id` | [PARCIAL] | aplicado (`project_plug.ex:13-21`) mas **sem teste cross-tenant automatizado** |
| RBAC realmente aplicado (matriz nos 5 perfis) | [PARCIAL] | só Master (`is_admin?`) e 1 ação (`manage_company_domain`); default permissivo (`rbac.ex:30-34`) |
| Gate de RBAC na API Bearer por papel | [AUSENTE] | `api_authorization_plug.ex:9-20` |
| Captcha no registro | [PARCIAL] | `auth_controller.ex:25-50`; operante no registro via `KeilaWeb.Captcha` (`auth_controller.ex:25-45`); ausente no login/reset |
| **Aceite de termos / política anti-spam no cadastro** | [AUSENTE] | não há campo/registro de aceite (relacionado a `policy_version`/`policy_url` nunca populados) |
| **Backup documentado + plano de incidente/notificação ANPD** | [AUSENTE] | não há runbook nem processo documentado no código |

## 15. Checklist de operação

| Item operacional | Estado | Evidência / lacuna |
|------------------|--------|--------------------|
| Cadastro/verificação/exclusão de domínios por empresa (UI) | [OK] | `domain_controller.ex:24-69`; `templates/domain/index.html.heex` (colunas SPF/DKIM/DMARC) |
| **Painel de domínios pendentes/falhos (visão Master agregada)** | [AUSENTE] | só listagem por projeto; sem agregação de domínios pendentes na instância |
| **Re-verificação automática de DNS (detecção de drift)** | [PARCIAL] | `reverificar_todos/0` existe (`deliverability.ex:99-104`) mas não agendado no crontab Oban |
| Pausa automática por reputação (bloqueia empresa + auditoria) | [PARCIAL] | `reputation.ex:74-107` cobre spam+hard bounce; sem unsubscribe/soft bounce |
| **Runbook de pausa/retomada de empresa** | [PARCIAL] | mecanismo existe (`Empresas.bloquear`/`desbloquear`, `empresa_admin_controller.ex:156-161`); **runbook documentado ausente** |
| **Alertas (spam/bounce/DNS/KYB pendente)** | [AUSENTE] | reputação só reage internamente; sem notificação ativa a operadores; sem webhooks de saída |
| Gate de KYB no envio com auditoria | [OK] | `empresas.ex:93-111`; `worker.ex:41,67-75` |
| Workflow KYB pelo Master (aprovar/rejeitar/reenviar convite) | [OK] | `empresa_admin_controller.ex:82-115,156-161` |
| **Fila de aprovação de campanha de alto volume** | [AUSENTE] | não há aprovação em nível de campanha; única aprovação é KYB de empresa (tenant) |
| **Enforcement de limites diário/mensal por empresa** | [AUSENTE] | `limite_diario`/`limite_mensal` declarativos, nunca lidos no worker; só ledger de créditos legado por Account |
| Quota/créditos de envio (ledger legado por Account) | [OK] | `accounts.ex:138-339`; `mailings.ex:898-968` (desacoplado da Empresa) |
| **Retenção/expurgo agendado (logs, eventos, contatos inativos)** | [AUSENTE] | sem cron de retenção; `consent_logs`/`audit_logs` sem política de expurgo |
| **Onboarding com DPA/DPO** | [PARCIAL] | campos `dpo_nome`/`dpo_email` existem só no `update_changeset` (sem UI, sem rota `:edit`); sem fluxo de DPA |
| Trilha de auditoria de ações críticas (empresa/domínio/impersonation/reputação) | [OK] | `auditoria.ex:47-81`; call sites confirmados |
| **Tela de Compliance para consultar `audit_logs`** | [PARCIAL] | `auditoria.ex:83-106` (list_por_projeto/recentes) existe; sem controller/view; `view_compliance_logs` nunca checada |
| Stats de campanha em tempo real para operação | [OK] | `campaign_stats_live.ex`; `mailings.ex:948-998` |
| **Dashboard Master (volume/taxas/empresas em risco)** | [AUSENTE] | só admin de instância/empresas/usuários/projetos |
| Promoção/criação de super admin documentada | [OK] | `release_tasks.ex:181` (auditado); `scripts/create_admin.sh` (GUIA_ADMIN_MULTI_TENANT.md) |

**Prioridades operacionais imediatas (derivadas das lacunas acima):** (1) agendar `reverificar_todos/0` e um cron de score de reputação no Oban; (2) construir o painel Master de domínios pendentes e empresas em risco; (3) ativar enforcement dos limites diário/mensal por empresa antes de qualquer aumento de volume; (4) documentar runbooks de pausa/retomada, retenção/expurgo e incidente/ANPD; (5) implementar o envio real das automações (`dispatch_run`), hoje um no-op.

---

## 16. Sugestoes de telas

A coluna "Status atual" reflete o que existe em runtime na verdade-base; "Acao" descreve o que falta construir/ajustar.

| Tela | Status atual | Acao (novo/ajuste) | Ancora no codigo |
|---|---|---|---|
| Master > Empresas (lista) | [PARCIAL] existe index com status operacional, labels e acoes KYB | Adicionar colunas plano, %spam (de `Keila.Reputation`), dominios pendentes/verificados (de `email_domains`) e limites; botoes Aprovar/Rejeitar/Bloquear ja existem; adicionar "Pausar/Despausar" e visao de risco | `lib/keila_web/controllers/empresa_admin_controller.ex:156-161`; `lib/keila_web/templates/empresa_admin/index.html.heex`; `lib/keila_web/views/empresa_admin_view.ex:21-42`; rotas `lib/keila_web/router.ex:124-131` |
| Master > Empresa (cadastro) | [PARCIAL] form coleta apenas 3 campos (nome, cnpj, email_responsavel) | Estender form para capturar `responsavel_nome`, `telefone`, `segmento`, `site`, `plano`, `limite_diario`, `limite_mensal`, `dominio_principal`, `subdominio_envio`, `dpo_nome`, `dpo_email`, `observacoes` (todos ja no schema/changesets) | `lib/keila_web/templates/empresa_admin/new.html.heex:17-49`; `lib/keila/empresas/empresa.ex:68-83,100-122` |
| Master > Empresa (edicao/governanca) | [AUSENTE] nao ha rota/controller `:edit`/`:update` | Criar tela de edicao plugando `Empresas.atualizar/2` (plano, limites, dominio, DPO, dados comerciais) | `lib/keila/empresas/empresas.ex:79-84`; `lib/keila/empresas/empresa.ex:100-122` (sem call site hoje) |
| Master > Dashboard (cartoes agregados) | [AUSENTE] so existe admin por entidade, sem agregacao | Criar dashboard com volume/taxas globais, empresas em risco (spam>limiar), dominios pendentes, KYB pendente | fontes de dados: `lib/keila/reputation.ex`, `email_domains`, `empresas` |
| Empresa > Dominio (assistente DNS) | [PARCIAL] tela existe com SPF/DKIM/DMARC e "verificar agora", protegida por RBAC | Transformar em assistente passo-a-passo; expor instrucoes de CNAME (DKIM/tracking) e alinhamento; hoje DKIM e best-effort e nao entra no criterio verified, e nao ha CNAME | `lib/keila_web/controllers/domain_controller.ex:24-69,97-114`; `lib/keila_web/templates/domain/index.html.heex:9,48-66`; `lib/keila/deliverability.ex:69-176`; rotas `lib/keila_web/router.ex:154-157` |
| Empresa > Onboarding LGPD (DPA/DPO/politica) | [AUSENTE] campos `dpo_nome`/`dpo_email` so no `update_changeset`, sem UI; `policy_version`/`policy_url` nunca preenchidos | Criar fluxo de onboarding capturando DPO, aceite de DPA e versao/URL da politica (alimentar `consent_logs.policy_version/policy_url`) | `lib/keila/empresas/empresa.ex:100-122`; `lib/keila/consent/log.ex:18-20` (campos existentes, nunca populados) |
| Contatos > Import (validacao + base legal + origem) | [PARCIAL] import roda, mas assume `legal_basis="legitimate_interest"` e `source="import"` hardcoded; sem MX, sem threshold de invalidos, sem dedupe intra-arquivo | Adicionar selecao de base legal/origem pelo usuario, validacao MX (`EmailHygiene.valid_mx?` existe mas nao e chamada), threshold de invalidos e dedupe no CSV; gravar `consent_logs` e `audit_log` da operacao | `lib/keila/contacts/import.ex:136-152`; `lib/keila/contacts/email_hygiene.ex:54-74`; `lib/keila/consent.ex:31-64` |
| Campanha > Pre-voo (checklist de envio) | [PARCIAL] gates existem no backend (`deliverable_check`) mas nao como tela de checklist | Criar painel de pre-voo exibindo: dominio verificado, link de descadastro no corpo, sender, KYB liberado, supressao; reusar `deliverable_check` | `lib/keila/mailings/mailings.ex:1128-1150` (gates: `campaign_has_unsubscribe?`, `sender_domain_liberado?`); `lib/keila_web/live/campaign_edit_live.ex` |
| Empresa > Preference center / Portal do titular | [AUSENTE] `Keila.DataSubject.*` e `Keila.Suppressions.*` completos no contexto, sem rota/controller/LiveView | Criar portal publico do titular (Art.18: acesso/portabilidade/eliminacao/anonimizacao/revogacao) e preference center; e painel admin para atender DSR e gerir supressao | `lib/keila/data_subject.ex:19-134`; `lib/keila/suppressions.ex:89-128` (sem referencia em `router.ex`) |
| Empresa > Usuarios (convite com papel) | [PARCIAL] `TeamController` convida sempre como `operator` (hardcode `member`), sem selecao de papel nem gestao de papeis | Adicionar seletor de papel (owner/operator/viewer/compliance) no convite e tela para alterar `UserGroupRole` existente; `manage_company_users` definido mas sem tela | `lib/keila_web/controllers/team_controller.ex` (hardcode `role: "member"`); `lib/keila_web/controllers/invite_controller.ex:115-117`; `lib/keila/auth/auth.ex:149-154` |
| Empresa > Compliance (audit_logs) | [PARCIAL] `auditoria.ex` tem `list_por_projeto`/`list_recentes`, mas sem tela; `view_compliance_logs` nunca checada | Criar tela de Compliance listando `audit_logs` por projeto, gated por papel compliance via RBAC | `lib/keila/auditoria.ex:83-106`; `lib/keila/auth/auth.ex:153` (permissao definida, sem UI) |

Resumo: ja existem (mesmo que parciais) Master>Empresas lista/cadastro, Empresa>Dominio, Campanha>editor com gates, Empresa>Usuarios (convite). Faltam por completo: Master>Dashboard agregado, Master>Empresa edicao, Empresa>Onboarding LGPD, Portal do titular/Preference center e tela de Compliance.

## 17. Criterios de aceite para desenvolvimento

| # | Regra inegociavel | Implementacao/teste hoje (verdade-base) | Criterio objetivo de aceite |
|---|---|---|---|
| 1 | Sender sem dominio validado -> envio BLOQUEADO | [PARCIAL] Gate universal no core (`deliver_campaign` e `deliverable_check`) via `Keila.Deliverability.dominio_liberado?`, MAS progressivo: dominio NAO cadastrado em `email_domains` libera por padrao salvo `REQUIRE_VERIFIED_DOMAIN`. Gate e por campanha, nao por destinatario no worker | Com `REQUIRE_VERIFIED_DOMAIN` ligado, campanha cujo dominio do `from_email` nao tem `EmailDomain` status=verified resulta em rollback `:domain_not_verified` e zero recipients enviados. Teste deve cobrir dominio inexistente, pending e failed | `lib/keila/mailings/mailings.ex:613,773-781,1144`; `lib/keila/deliverability.ex:114-127,140-142` |
| 2 | Campanha sem link de descadastro no corpo -> nao envia | [OK] `campaign_has_unsubscribe?` aplicado em `deliver_campaign` e `deliverable_check`; header List-Unsubscribe One-Click sempre injetado | Campanha cujo corpo (text/html/mjml/json/template) nao contem marcador (`@unsubscribe_markers`) e rejeitada com `:no_unsubscribe_link`; campanha com `{{ unsubscribe_link }}` passa. Verificar header presente no email construido | `lib/keila/mailings/mailings.ex:609-611,1063-1102`; `lib/keila/mailings/builder.ex:361-365` |
| 3 | Envio p/ supressao/opt-out/hard-bounce -> nunca ocorre | [OK] `ensure_nao_suprimido` no worker por destinatario, antes de construir/enviar; `suprimido?/2` cobre escopo empresa+global; supressao automatica em hard bounce/complaint/unsubscribe; idempotente e por e-mail | E-mail presente em `suppressions` (escopo do projeto OU global) nunca recebe envio mesmo apos recriacao do contato; hard bounce/complaint/opt-out inserem na lista automaticamente. Teste de re-importacao apos supressao | `lib/keila/mailings/worker.ex:40,79-86`; `lib/keila/suppressions.ex:67-85`; `recipient_actions/{hard_bounce,complaint,unsubscription}.ex` |
| 4 | Import >X% invalidos ou sem base legal -> bloqueado | [AUSENTE] Sem threshold de invalidos (linhas invalidas viram nil e sao puladas silenciosamente); base legal hardcoded `legitimate_interest`, usuario nao declara; sem MX | Import deve (a) abortar/sinalizar acima de X% de invalidos configuravel; (b) exigir base legal declarada pelo usuario; (c) opcionalmente rodar `valid_mx?`. Hoje so `disposable?` roda e um erro de changeset aborta a transacao inteira | `lib/keila/contacts/import.ex:136-152`; `lib/keila/contacts/email_hygiene.ex:43-74` |
| 5 | Empresa acima do limiar de spam -> pausa automatica auditada | [OK] `Keila.Reputation`: spam>0,3%, hard bounce>5%, amostra minima 500; `auto_pause` chama `Empresas.bloquear` + `Auditoria`; disparado em hard_bounce e complaint | Campanha com amostra>=500 e taxa de spam>0,3% (ou hard bounce>5%) bloqueia a empresa e grava `audit_log`; novos disparos param via gate de empresa no worker. Nota: unsubscribe e soft bounce NAO disparam pausa hoje | `lib/keila/reputation.ex:21-23,46-50,74-107`; `lib/keila/mailings/worker.ex:69-73` |
| 6 | Conta nova + alto volume -> fila de aprovacao | [AUSENTE] Nao existe fila de aprovacao por volume/novidade da conta; limites `limite_diario`/`limite_mensal` declarativos, nunca aplicados; sem warmup | Definir politica: conta/empresa nova acima de volume X entra em estado de revisao manual antes de liberar. Pre-requisito: enforcement de `limite_diario`/`limite_mensal` (inexistente) e contador de uso por empresa (inexistente) | `lib/keila/empresas/empresa.ex` (limites sem enforcement); ausencia confirmada de tabela usage |
| 7 | Empresa sem KYB -> projeto nao libera envio | [OK] `Empresas.pode_enviar?/projeto_pode_enviar?` exige `kyb_status=aprovado` e status em [convidada, ativa]; aplicado por destinatario no worker; projeto sem empresa (nil) preserva legado | Empresa com `kyb_status` pendente/rejeitado nao envia: worker cancela job com `{:error, :empresa_bloqueada}` e marca recipient failed. Projeto sem empresa vinculada continua enviando (comportamento legado documentado) | `lib/keila/empresas/empresas.ex:93-111`; `lib/keila/mailings/worker.ex:41,67-75,201-213` |
| 8 | Toda acao critica (incl. impersonation) em audit_logs | [PARCIAL] `audit_logs` + `Keila.Auditoria` (IP/UA/ator/metadata best-effort); impersonation auditada ANTES de trocar sessao; empresa/KYB/dominio/promocao admin/pausa auditados. MAS login/logout/reset NAO auditados; import/export/delete de contatos NAO auditados | Cada acao critica gera 1 linha em `audit_logs` com actor, entity, ip, user_agent. Aceite exige FECHAR gaps: auditar login/logout/falha de login/reset (`auth_controller.ex` sem `Auditoria.registrar_conn`) e import/export/delete de contatos | `lib/keila/auditoria.ex:47-81`; `lib/keila_web/controllers/user_admin_controller.ex:127-140`; gaps em `auth_controller.ex` e `contacts/import.ex` |
| 9 | Cross-tenant falha | [OK] `project_plug` retorna 404 se usuario nao e membro do grupo do projeto; `get_user_project` usa `Auth.user_in_group?`; API valida posse do token + pertencimento ao projeto | Usuario/token do projeto A recebe 404/403 ao acessar recurso do projeto B. ATENCAO: isolamento e por pertencimento, NAO por papel — viewer/compliance tem mesmo acesso de owner intra-tenant; API key nao respeita papel (gap RBAC) | `lib/keila_web/helpers/project/project_plug.ex:13-21`; `lib/keila/projects.ex:111-118`; `lib/keila_web/api/plugs/api_authorization_plug.ex:9-20` |

Observacao transversal: o enforcement de papeis (owner/operator/viewer/compliance) so existe em 1 acao (`manage_company_domain` via `Keila.Rbac.can?/3` em `domain_controller.ex:105`) e tem default permissivo (usuario sem papel = dono, `rbac.ex:28-35`). Qualquer criterio de aceite que dependa de restricao por papel exige cabear `Keila.Rbac.can?/3` nos demais controllers de projeto antes de ser testavel.

## 18. Pontos de atencao para evitar spam e bloqueio de dominio

| Risco | Estado no codigo | Recomendacao | Ancora |
|---|---|---|---|
| Dominio de tracking COMPARTILHADO (maior risco atual) | [AUSENTE] Tracking domain e FIXO: todos os links de clique/abertura e o pixel usam `KeilaWeb.Endpoint` (host unico da instancia). Sem campo de tracking domain por empresa nem CNAME. Reputacao de spam/blocklist de uma empresa contamina TODAS | Implementar custom tracking domain por empresa via CNAME verificavel; isolar reputacao de links/host por tenant. Reusar o suporte a CNAME hoje cloud-only | `lib/keila/mailings/builder.ex:449,465,483`; `lib/keila/tracking/tracking.ex:60-77`; `extra/keila_cloud/dns.ex:11-21` (CNAME cloud-only, nao usado no gate universal) |
| Gatilhos por "abertura" nao confiaveis (Apple MPP) | [OK] tracking de abertura existe (pixel HMAC, anti-bot) mas Apple Mail Privacy Protection pre-carrega pixels inflando aberturas. Automacoes EVO disparam por status, nao por abertura — bom; metricas de UI ainda exibem abertura | Priorizar CLIQUE como sinal de engajamento em segmentacao/automacao/reputacao; tratar abertura como sinal fraco. Nao usar abertura para gatilho de automacao (ja e o caso) | `lib/keila/mailings/builder.ex:410-491` (open/click tracking); `lib/keila/automations/recipes.ex` (gatilho por status, nao abertura) |
| Complaint vira `unsubscribed` (nao supressao permanente diferenciada) | [OK] complaint marca contato `:unsubscribed` E insere em `suppressions` com reason `complaint`; reputacao avaliada. A supressao por e-mail ja sobrevive a recriacao do contato | Avaliar tratar complaint como supressao permanente/dura distinta de opt-out simples (mesma trava ja protege; e questao de politica de re-inscricao e relatorio). Hoje ja bloqueia re-envio por e-mail | `lib/keila/mailings/recipient_actions/complaint.ex:31-38`; `lib/keila/suppressions.ex:67-85` |
| Sem warmup / rampa de aquecimento | [AUSENTE] Zero codigo de warmup/ramp-up. Rate limit e fixo por sender/adapter (`rate_limit_per_second/minute/hour`), nao evolui por idade do sender/dominio nem por dia. Volume alto desde o dia 1 = risco de blocklist | Implementar cota diaria progressiva por IP/dominio/idade do sender; combinar com a fila de aprovacao do criterio 6. Tabelas `ip_pools`/`warmup_schedules` ausentes do schema | `lib/keila/mailings/rate_limiter.ex:62-88`; `lib/keila/mailings/schemas/sender_config.ex:12-14` |
| Provedor de IA fora do Brasil = transferencia internacional LGPD | [OK funcional/risco LGPD] OpenRouter (`openrouter.ai`) recebe conteudo de e-mail/marca para geracao MJML e brand research. E transferencia internacional de dados que pode conter PII no prompt | Documentar base legal e clausulas de transferencia internacional; minimizar PII enviada a IA; permitir opt-out por empresa no onboarding LGPD; registrar no DPA | `lib/keila/integrations/open_router.ex` (@api_url openrouter.ai); `lib/keila/ai/{email_editor,brand_research}.ex` |
| Return-Path / envelope-from por empresa ausente | [AUSENTE] Sem manipulacao de Return-Path/VERP; builder so seta From/Reply-To; no SES o envelope depende do MAIL FROM do provedor. Afeta alinhamento SPF e processamento de bounce dedicado por empresa | Implementar Return-Path/MAIL FROM por empresa para alinhamento SPF e isolamento de bounce; pre-requisito para reputacao por tenant | `lib/keila/mailings/builder.ex` (sem Return-Path); `lib/keila/mailer.ex:24` |
| Re-verificacao periodica de DNS nao agendada (drift SPF/DMARC) | [PARCIAL] `reverificar_todos/0` existe mas NAO esta no crontab do Oban; status `verified` pode ficar obsoleto indefinidamente; DKIM nao e exigido para verified (so SPF+DMARC) | Agendar `reverificar_todos/0` no crontab Oban; incluir DKIM no criterio de verified; alertar empresa em caso de drift | `lib/keila/deliverability.ex:99-104,166-176`; `config/config.exs:103-116` |
| Bot detection limitado infla metricas | [PARCIAL] ha filtro anti-bot (`is_bot`) no tracking via HMAC, mas e basico; bots/prefetch inflam aberturas e cliques, distorcendo reputacao e segmentacao | Endurecer deteccao (user-agent, timing, prefetch conhecido); combinar com priorizacao de clique do item acima | `lib/keila/tracking/tracking.ex` (`is_bot`/anti-bot HMAC) |
| Monitoramento de reputacao so interno (sem provedor) | [AUSENTE] Reputacao calculada so de metricas internas por campanha; sem ingestao de SES GetReputation/Google Postmaster; pausa so reage a webhook agregado por campanha | Integrar reputation dashboard do provedor (SES) e Google Postmaster; ampliar `breach/1` para unsubscribe e soft bounce (hoje so spam+hard bounce) | `lib/keila/reputation.ex:48-50,112-118` (unsubscribe_rate calculado mas nao usado) |

Prioridade de mitigacao: (1) CNAME de tracking por empresa - elimina o maior vetor de contaminacao cross-tenant de reputacao; (2) warmup + fila de aprovacao de conta nova; (3) Return-Path por empresa; (4) agendar re-verificacao de DNS e exigir DKIM; (5) ampliar `breach/1` e ingestao de reputacao do provedor.