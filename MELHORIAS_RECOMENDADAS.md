# Fluxo Email MKT - Melhorias Recomendadas

## Prioridade Alta (Implementar Primeiro)

### 1. Tradução Completa para Português (i18n)
**Status atual:** Interface em inglês com suporte a i18n via Gettext
**O que fazer:** O Keila já suporta múltiplos idiomas (de, en, es, fr, hu, it, bg). Adicionar `pt-BR` como locale padrão.
- Criar arquivo `priv/gettext/pt/LC_MESSAGES/default.po`
- Traduzir todas as strings da interface
- Definir `default_locale: "pt"` no config
- Impacto: UX muito melhor para empresas brasileiras

### 2. Dashboard com Métricas por Empresa
**Status atual:** Página de projetos simples
**O que fazer:** Dashboard rico ao entrar no projeto mostrando:
- Total de contatos ativos
- Campanhas enviadas no mês
- Taxa média de abertura / cliques
- Gráfico de crescimento da lista
- Próximas campanhas agendadas

### 3. Configurar Sender Compartilhado Fluxo
**O que fazer:** Configurar um sender SMTP da Fluxo como "shared sender" para empresas que não têm SMTP próprio. Isso permite onboarding instantâneo.

### 4. WhatsApp / Webhook de Notificação
**O que fazer:** Adicionar webhook quando:
- Campanha é enviada
- Bounce rate passa de X%
- Novo contato se inscreve
- Isso permite integrar com bots de WhatsApp ou Chatwoot

---

## Prioridade Média (Próximas Sprints)

### 5. Automações de Email (Drip Campaigns)
**Status atual:** Keila só tem campanhas únicas ou agendadas
**O que fazer:** Adicionar automações:
- Sequência de boas-vindas (welcome series)
- Email após X dias sem abrir
- Aniversário / data especial
- Usando Oban workers + nova tabela `automation_workflows`

### 6. Editor de Templates com Blocos Prontos
**Status atual:** Editor de blocos genérico
**O que fazer:** Criar biblioteca de blocos pré-prontos:
- Header com logo da empresa
- Footer com redes sociais
- Botão CTA com cores Fluxo
- Depoimentos / testemunhos
- Galeria de produtos

### 7. Relatórios PDF por Campanha
**O que fazer:** Gerar PDF com:
- Resumo da campanha (assunto, data, total enviado)
- Métricas: aberturas, cliques, bounces, descadastros
- Gráfico de timeline de aberturas
- Top links clicados
- Mapa de calor de cliques (nice to have)

### 8. Integração com Chatwoot (Suporte)
**O que fazer:** Já que a Fluxo tem Chatwoot rodando:
- Botão "Precisa de ajuda?" no painel
- Widget do Chatwoot integrado
- Abertura de ticket automática por email

---

## Prioridade Baixa (Roadmap Futuro)

### 9. API Pública Documentada
**Status atual:** API existe mas não tem docs públicas
**O que fazer:** Criar documentação Swagger/OpenAPI para que empresas integrem:
- POST /api/v1/contacts (criar contato)
- POST /api/v1/campaigns (criar campanha)
- GET /api/v1/campaigns/:id/stats

### 10. Landing Pages Builder
**O que fazer:** Editor visual para criar landing pages de captura conectadas aos formulários.

### 11. A/B Testing
**O que fazer:** Enviar duas versões de assunto/conteúdo para % da lista e enviar o vencedor pro restante.

### 12. Domínio Customizado por Empresa
**O que fazer:** Permitir que cada empresa tenha seu domínio de tracking e links (ex: `links.empresa.com.br` em vez de `emailmkt.fluxodigitaltech.com.br`).

### 13. Planos e Billing
**Status atual:** Keila Cloud tem billing integrado (Paddle)
**O que fazer:** Ativar sistema de créditos/quotas para cobrar por volume de envio:
- `ENABLE_QUOTAS=true`
- Definir pacotes: Starter (1000/mês), Pro (10000/mês), Business (50000/mês)
- Integrar gateway BR (Stripe BR, Pagar.me, etc.)

---

## Melhorias de Infraestrutura

### 14. CDN para Assets e Uploads
- Configurar Cloudflare ou BunnyCDN na frente
- Servir uploads de imagens via CDN (USER_CONTENT_BASE_URL)
- Cache de assets estáticos

### 15. Backup Automatizado
- Cronjob de pg_dump diário para o banco `fluxo_emailmkt`
- Backup dos uploads para S3/R2
- Retenção de 30 dias

### 16. Monitoramento
- Healthcheck endpoint já existe (`/health`)
- Configurar Uptime Kuma ou similar
- Alertas de bounce rate alto
- Alertas de fila de envio travada

### 17. Rate Limiting por Empresa
- Limitar envios por hora/dia por projeto
- Proteger reputação do IP compartilhado
- Configurável via admin

---

## Estimativa de Esforço

| Melhoria | Esforço | Impacto |
|----------|---------|---------|
| Tradução pt-BR | 2-3 dias | Alto |
| Dashboard métricas | 3-5 dias | Alto |
| Sender compartilhado | 1 dia | Alto |
| Webhooks | 2-3 dias | Médio |
| Automações (drip) | 1-2 semanas | Alto |
| Templates prontos | 3-5 dias | Médio |
| Relatórios PDF | 3-5 dias | Médio |
| Integração Chatwoot | 1-2 dias | Médio |
| API docs | 2-3 dias | Médio |
| Landing pages | 2-3 semanas | Médio |
| A/B testing | 1 semana | Médio |
| Billing | 1-2 semanas | Alto |
