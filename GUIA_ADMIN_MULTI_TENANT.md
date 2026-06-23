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

## Super Admin (Master) — quem gerencia as empresas

O **Master Admin** é o super usuário global da Fluxo: cadastra/aprova/bloqueia
empresas, valida o **KYB**, e tem acesso a todas as telas `/admin/*`.
Tecnicamente, é um usuário com a permissão `administer_keila` no grupo raiz.

### Criar (ou promover) um Super Admin

**Em produção (Docker)** — após subir o código e rodar as migrations:

```bash
# 1) deploy do código + migrations
docker compose -f docker-compose.prod.yml up -d --build
docker exec fluxo-emailmkt-app bin/keila eval "Keila.ReleaseTasks.migrate()"

# 2) criar/promover o super admin
./scripts/create_admin.sh admin@fluxodigitaltech.com.br SuaSenhaForte123
```

**Em desenvolvimento local:**

```bash
mix ecto.migrate
mix run -e 'Keila.ReleaseTasks.create_admin("admin@fluxo.com", "SuaSenhaForte123")'
```

Comportamento da task `Keila.ReleaseTasks.create_admin/2` (**idempotente**):

- E-mail **não existe** → cria o usuário, ativa e concede o papel de admin.
- E-mail **já existe** → apenas **promove** o usuário a Master Admin.
- Pode rodar quantas vezes quiser sem efeito colateral.

> A promoção fica registrada na trilha de auditoria (`audit_logs`).

---

## Fluxo de Cadastro de Empresa com KYB (recomendado)

> Este é o fluxo de governança multiempresa. O Master cadastra a empresa, e o
> **disparo só é liberado após o KYB ser aprovado** (regra inegociável: sem KYB,
> sem envio).

### 1. Cadastrar a empresa (Master)

Acesse **`/admin/empresas`** → **Cadastrar empresa** e informe: nome, CNPJ
(validado), responsável/e-mail, e — opcionalmente — telefone, segmento, site,
plano, limites diário/mensal, domínio, subdomínio de envio e DPO/Encarregado.

Ao salvar, o sistema cria o **Projeto isolado** da empresa e dispara o **convite**
por e-mail para o responsável. A empresa entra com **KYB `pendente`**.

### 2. Validar o KYB (Master)

Ainda em `/admin/empresas`, na linha da empresa:

- **Aprovar KYB** → libera o envio. (valide antes: CNPJ, site ativo, legitimidade)
- **Rejeitar** → registra o motivo e mantém o envio bloqueado.
- **Bloquear / Reativar** → suspende ou retoma os disparos (ex.: reputação/abuso).

Enquanto o KYB não estiver **aprovado** (ou a empresa estiver **bloqueada**), o
worker **cancela qualquer disparo** daquele projeto automaticamente.

### 3. O responsável aceita o convite

O responsável clica no link do e-mail, define a senha e vira **dono do projeto**
da empresa. A empresa passa de `convidada` para `ativa`.

### 4. Operar

A empresa configura remetente/domínio, importa contatos, cria listas/segmentos,
campanhas e automações — tudo isolado no próprio projeto.

> **Supressão automática:** hard bounce, reclamação de spam (complaint) e
> descadastro adicionam o e-mail à lista de supressão (por empresa + bloqueio
> global), e o sistema nunca reenvia para endereços suprimidos.

---

## Fluxo de Cadastro de Nova Empresa (legado / manual)

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
| Admin - Empresas (cadastro + KYB) | `/admin/empresas` |
| Admin - Cadastrar empresa | `/admin/empresas/nova` |
| Admin - Usuários | `/admin/users` |
| Admin - Senders | `/admin/senders` |
| Admin - Sistema | `/admin/instance` |
| Projetos da empresa | `/` (após login) |
| API Docs | Disponível via API keys por projeto |

> Todas as rotas `/admin/*` exigem um **Super Admin (Master)**. Ações críticas
> (impersonation/modo suporte, cadastro e KYB de empresa, bloqueio) ficam
> registradas em `audit_logs`.

---

## Segurança

- Senhas hasheadas com **Argon2**
- Sessões baseadas em tokens com expiração
- Captcha no registro (hCaptcha ou Friendly Captcha)
- Rate limiting nas APIs
- Isolamento de dados via foreign keys no banco
- Validação de acesso em cada requisição (ProjectPlug)
