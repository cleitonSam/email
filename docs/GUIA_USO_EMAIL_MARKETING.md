# Guia de Uso — Email Marketing Fluxo

Material de apoio para os times de **Atendimento** e **Onboarding**. Cobre
os fluxos novos: contatos por categoria, escolha de unidade, identidade
da empresa nos templates.

---

## 1. Identidade da empresa (configurar uma vez)

Por que existe: garantir que **logo, cores, nome e contatos** apareçam de
forma consistente em **todos** os emails — sem precisar editar cada template.

**Onde configurar**: menu lateral → **Configurações** → **Identidade da Empresa**.

Campos:
- Nome da empresa
- Logo (URL ou upload)
- Cor primária / cor de destaque / cor de fundo
- WhatsApp
- Endereço

**Importante**: ao salvar, **todos os emails ativos** passam a usar os novos
valores no próximo envio ou preview. Não é necessário abrir cada template.

---

## 2. Contatos: Membros vs Oportunidades

No módulo **Contatos** existem agora 3 abas de tipo:

| Aba | O que mostra |
|-----|--------------|
| **Todos** | Todos os contatos do projeto |
| **Members** | Apenas alunos matriculados (vindos do EVO como `member`) |
| **Oportunidades** | Apenas leads/prospects (vindos do EVO como `prospect`/`opportunity`) |

A separação acontece automaticamente com base no tipo informado pelo EVO no
último sync. Imports manuais de CSV ficam apenas em "Todos" (sem tipo).

> **Dúvida frequente**: "criei o contato à mão e ele não aparece em Members."
> Correto — só contatos importados do EVO carregam o tipo. Para forçar, edite
> o contato e adicione `evo_type=member` em dados customizados.

---

## 3. Categorias de contato

Categoria é um **segmento pré-definido** que agrupa contatos por uma regra
de negócio. Aparecem na lista de segmentos ao montar uma campanha.

### Categorias disponíveis

| Categoria | Quem entra |
|-----------|-----------|
| **Aniversariantes** | Membros cuja `data de nascimento` casa com o dia atual |
| **Ausentes 1 a 7 dias** | Membros com última visita entre 1 e 7 dias atrás |

### Como usar em uma campanha

1. Em **Campanhas → Nova Campanha**, abra **Configurações** (ícone de engrenagem).
2. No campo **Segmento**, selecione a categoria desejada.
3. O contador de destinatários abaixo do select atualiza ao vivo.
4. Continue normalmente: assunto, template, agendamento.

### Adicionar uma nova categoria (time técnico)

Categorias são definidas em código (`lib/keila/contacts/categories.ex`).
Solicite ao time técnico: "adicionar categoria X com filtro Y". Não há
ferramenta self-service para isso ainda.

---

## 4. Multi-unidade no envio

### Quando você verá o seletor

- **Empresa com 1 unidade**: o seletor **não aparece**. O envio cobre todos
  os contatos do projeto.
- **Empresa com 2+ unidades**: aparece um campo **Unidade** com:
  - "Todas as unidades" (default — envia para contatos de qualquer unidade)
  - Cada unidade ativa listada por nome

### Como funciona

Quando você seleciona uma unidade específica, o envio filtra automaticamente
para incluir **somente contatos sincronizados daquela unidade**. Combine com
um segmento (ex: "Aniversariantes") para enviar "aniversariantes da Unidade
Centro" sem montar segmento manual.

### Onde está o seletor

Em **Campanhas → Configurações** (ícone engrenagem na edição da campanha),
logo abaixo do seletor de **Segmento**.

---

## 5. Templates pré-definidos

Disponíveis na biblioteca de templates ao criar uma campanha:

| Template | Sugestão de uso |
|----------|----------------|
| Boas-vindas (matrícula) | Novo aluno |
| Feliz aniversário | Categoria Aniversariantes |
| Oferta limitada | Promoção pontual |
| Newsletter do mês | Comunicação periódica |
| Avaliação física | Convite para avaliação |
| Convite para evento | Eventos da unidade |
| Reativação de aluno | Categoria Ausentes 1-7 dias |
| Indicação de amigo | Programa de indicação |

Todos os templates **respeitam a identidade da empresa** automaticamente — logo,
cores e dados de contato vêm da configuração de Identidade.

---

## 6. Fluxo recomendado de onboarding

Roteiro para apresentar ao novo cliente:

1. **Configurar Identidade da Empresa** (5 min)
   - Logo, cores, WhatsApp, endereço.
2. **Conectar unidades EVO** (1 min por unidade)
   - Em **Configurações → Unidades EVO**.
   - Aguardar primeiro sync (importa membros e oportunidades).
3. **Validar contatos importados** (2 min)
   - Abrir **Contatos**, conferir tabs Members/Oportunidades.
4. **Disparar uma campanha de teste** (5 min)
   - Selecionar template "Boas-vindas".
   - Segmento: criar um teste pequeno ou usar uma categoria.
   - Se multi-unidade: escolher uma unidade.
   - Enviar para si mesmo via **Pré-visualizar e enviar teste**.
5. **Conferir o preview** (1 min)
   - Logo, cores e dados batem com a identidade configurada.

---

## 7. Perguntas frequentes

**A categoria Aniversariantes está vazia, mas tenho membros aniversariando.**
Verifique: (a) os membros vieram do EVO com `data.birth_date` preenchido;
(b) o sync rodou hoje. O filtro usa o dia/mês atual.

**A categoria Ausentes está sempre vazia.**
Depende do campo `last_visit_at` no sync EVO. Confirme com o time técnico
se este campo está sendo populado nesta unidade.

**Atualizei o logo e os emails antigos não mudaram.**
Emails **já enviados** ficam congelados (registro histórico). **Próximos
envios e previews** usam o logo novo automaticamente.

**Quero usar a logo só em uma campanha específica.**
Não recomendado. Para "branding pontual", crie um template novo com a imagem
fixa via URL.

**Posso esconder o select de unidade mesmo tendo 2+ unidades?**
Não. Quando o projeto tem múltiplas unidades, o select é necessário para
evitar envio acidental cross-unidade.

---

## 8. Onde reportar problemas

- **Bug de exibição/UX** → time de Produto.
- **Variável de identidade não renderiza** → time Técnico (verificar
  `Brand.@default_brand` e o template).
- **Categoria nova/ajuste de filtro** → time Técnico (editar
  `Categories.catalog/0`).
