# Fluxo Email MKT - Guia de Administração Multi-Tenant

## Como Funciona

Cada **empresa cliente** da Fluxo recebe:
- Uma **conta de usuário** (email + senha)
- Um **Projeto** dentro do sistema (= workspace isolado)
- Acesso apenas aos SEUS dados: contatos, campanhas, formulários, templates

### Isolamento por Empresa

| Recurso | Isolamento |
|---------|-----------|
| Contatos | Cada empresa só vê seus próprios contatos |
| Campanhas | Campanhas são por projeto |
| Formulários | Forms de captura são por projeto |
| Templates | Templates de email por projeto |
| Senders (remetentes) | Cada empresa configura seu SMTP |
| Segmentos | Filtros de contatos por projeto |
| API Keys | Chaves de API vinculadas ao projeto |

---

## Fluxo de Cadastro de Nova Empresa

### 1. Criar Usuário (Admin)

Acesse `/admin/users` como admin e crie o usuário:
- Email: `contato@empresa.com.br`
- Senha: gerar senha temporária

O usuário receberá um email de ativação.

### 2. A Empresa Cria Seu Projeto

Após ativar a conta, o usuário entra no sistema e:
1. Clica em "Create Project" (ou "Criar Projeto")
2. Dá um nome ao projeto (ex: "Marketing - Empresa X")
3. Configura seu remetente (Sender) com as credenciais SMTP da empresa

### 3. Importar Contatos

A empresa pode:
- Importar CSV/TSV de contatos
- Criar formulários de captação
- Adicionar contatos manualmente

### 4. Criar e Enviar Campanhas

- Editor visual de blocos (drag & drop)
- Editor Markdown com preview
- Editor MJML para emails responsivos avançados
- Agendamento de envio
- Tracking de aberturas e cliques

---

## Variáveis de Ambiente Importantes

```bash
# Desabilitar auto-registro (recomendado para multi-tenant controlado)
DISABLE_REGISTRATION=true

# Habilitar quotas de envio por empresa (opcional)
ENABLE_QUOTAS=true

# Desabilitar criação de senders customizados (forçar shared senders)
DISABLE_SENDER_CREATION=false
```

---

## Gerenciar Empresas como Admin

### Listar Usuários
Acesse: `/admin/users`

### Adicionar Créditos de Envio (se ENABLE_QUOTAS=true)
Acesse o perfil do usuário em `/admin/users/:id/credits`

### Senders Compartilhados (Shared Senders)
Para oferecer envio sem que a empresa configure SMTP:
1. Acesse `/admin/senders`
2. Crie um sender compartilhado com o SMTP da Fluxo
3. As empresas poderão usá-lo nos seus projetos

---

## URLs do Sistema

| Funcionalidade | URL |
|---------------|-----|
| Login | `/auth/login` |
| Registro (se habilitado) | `/auth/register` |
| Admin - Usuários | `/admin/users` |
| Admin - Senders | `/admin/senders` |
| Admin - Sistema | `/admin/instance` |
| Projetos da empresa | `/` (após login) |
| API Docs | Disponível via API keys por projeto |

---

## Segurança

- Senhas hasheadas com **Argon2**
- Sessões baseadas em tokens com expiração
- Captcha no registro (hCaptcha ou Friendly Captcha)
- Rate limiting nas APIs
- Isolamento de dados via foreign keys no banco
- Validação de acesso em cada requisição (ProjectPlug)
