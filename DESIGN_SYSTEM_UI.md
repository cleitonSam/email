# Redesign da Plataforma — Fluxo Email MKT
## Direcao Visual + Design System + Layout das Telas (Master & Empresa)

> Documento de produto/UI. Ancorado nos **tokens reais da marca Fluxo** ('email/assets/tailwind.config.js' + 'styles.scss'), confirmados no site fluxodigitaltech.com.br. Stack-alvo: Phoenix LiveView + Tailwind + HEEx.
> Tema: escuro premium sobre navy · Primary #0066FF · Accent #00F2FE · Poppins/Inter. Legenda de ambiente: ambiente Master (Fluxo) x ambiente Empresa.

---

## 1. Direcao visual & principios

A Fluxo nao e um disparador de e-mails: e o **motor de vendas** da operacao do cliente. A interface precisa transmitir isso em cada pixel — tecnologia propria, IA sempre ligada, previsibilidade e controle. Quando o usuario abre a plataforma, a sensacao-alvo e a de **entrar na sala de comando de um motor**, nao a de preencher um formulario de newsletter. Painel escuro, instrumentos iluminados, dado em primeiro plano, energia azul-ciano correndo pelas bordas certas.

**Principios de UI (acionaveis):**

1. **Navy como palco, azul/ciano como energia.** O fundo (`--bg-base #020617`, `--bg-subtle #0A1F3D`, `--surface #0D2B52`) e sempre escuro e calmo — ele recua. A cor de marca (`--primary #0066FF` -> `--accent #00F2FE`) aparece com intencao: CTA principal, estado ativo, foco, KPI que importa, linha de grafico. Cor = energia/acao, nunca decoracao de fundo. Se tudo brilha, nada importa.

2. **Motor de vendas, nao disparador.** A linguagem visual prioriza performance e movimento: gradiente `fluxo-gradient` (135deg #0066FF -> #00F2FE) em CTAs e cabecalhos hero, animacoes contidas (`fade-in-scale`, `pulse-soft`, `glow`, `aurora` apenas em telas-vitrine). O verbo da interface e ligar/acionar ("Ligar motor", "Pronto para envio"), nunca apenas "enviar".

3. **Dado em primeiro plano.** KPIs, taxas e reputacao sao os herois da tela. Numeros grandes em Poppins, com `--accent` ou gradiente reservado para o valor que decide. O cromo (bordas, labels, chrome de navegacao) usa `--text-secondary`/`--text-muted` e recua. Hierarquia: numero > contexto > controle.

4. **Glass com moderacao.** Glassmorphism (`--surface-glass: rgba(13,43,82,.55) + backdrop-blur(12px)` + `border --border`) e reservado a overlays, modais, command palette e um eventual card de destaque. Superficies de trabalho (tabelas, formularios, listas) sao solidas (`--surface`, `--surface-2`) para legibilidade e desempenho. O site nao e glass pesado; a plataforma tambem nao.

5. **Bordas finas, hierarquia por superficie.** A profundidade vem do empilhamento de superficies (`--bg-base` < `--bg-subtle` < `--surface` < `--surface-2`) e de bordas sutis (`--border #1E2A44`, `--border-strong #2B3A5C`), nao de sombras pesadas. Sombra de marca (`shadow-fluxo`, `shadow-fluxo-lg`) so em elementos elevados/acionaveis (CTA, card em hover, popover).

6. **Foco e estado sempre visiveis.** Todo elemento interativo tem hover (`--hover`), foco (anel `--focus-ring` 2px + offset), ativo e selecao (`--selection`) explicitos. Estado nunca depende so de cor — sempre icone + label (saude da base, reputacao, status de envio).

7. **Premium = consistencia, nao enfeite.** Raio `rounded-2xl` em cards, `rounded-lg` em inputs/botoes, espacamento em escala de 4px, tipografia disciplinada. A sensacao de produto caro vem do ritmo e do silencio do navy, nao de efeitos.

**Como o tema escuro premium constroi a sensacao-alvo:** o navy profundo (#020617) cria contraste maximo (~17:1) com o texto branco-gelo (#F8FAFC), o que comunica clareza e precisao de instrumento. Os gradientes frios (azul -> ciano) lembram telemetria, fibra optica, fluxo de dados — reforcam "stack propria" e "tecnologia", nunca o calor de uma agencia criativa. O olho repousa no navy e e guiado pela energia ciano ate a acao seguinte.

**Master (Fluxo) x Empresa (tenant):**

| Eixo | Ambiente MASTER (Fluxo) | Ambiente EMPRESA (tenant) |
|---|---|---|
| Cor de assinatura | Ciano `--accent #00F2FE` | Azul `--primary #0066FF` |
| Barra superior | Topbar distinta com selo "Fluxo Master" + faixa/glow ciano (`--accent-strong`) na borda inferior da topbar | Topbar padrao, borda inferior `--border`, acento azul |
| Selo/identidade | Selo ciano fixo no canto da topbar (icone motor + label "MASTER") | Logo/nome da empresa; selo neutro |
| Borda de moldura | Hairline ciano no topo do viewport (1px, `--accent`) sinalizando "voce esta no modo operador da plataforma" | Sem hairline ciano; acento azul nos ativos |
| Acento de componentes | Estado ativo, tabs e KPIs-chave puxam ciano | Estado ativo e CTAs puxam azul `--primary` |

A regra mnemonica: **ciano = visao Fluxo (operador da plataforma), azul = visao Empresa (dono da operacao).** Isso evita que um admin Fluxo confunda em qual contexto/tenant esta agindo — diferenciacao reforcada por cor + selo + label, nunca so por cor.

**Nota dark-only:** a plataforma e **exclusivamente escura** (`darkMode` aplicado sempre via classes). Motivo: (a) coerencia com o site e com a sensacao de "sala de comando/motor"; (b) navy profundo maximiza o contraste e o destaque dos gradientes frios e dos KPIs; (c) reduz custo de manutencao e risco de regressao de contraste de manter dois temas; (d) telas de operacao/monitoramento ficam confortaveis em uso prolongado. Nao ha toggle claro/escuro; o investimento de design e concentrado em um unico tema impecavel.

## 2. Design System — Paleta de cores

Tokens semanticos nomeados (fonte da verdade). Contraste calculado sobre o fundo de uso tipico; quando o token e fundo, indica-se o texto recomendado sobre ele.

| Token | Hex | Uso | Contraste |
|---|---|---|---|
| `--bg-base` | #020617 | Fundo raiz do app (canvas, atras de tudo) | base — `--text` ~17:1 (AAA) |
| `--bg-subtle` | #0A1F3D | Faixas/seções, fundo de areas agrupadas | `--text` ~14:1 (AAA) |
| `--surface` | #0D2B52 | Card, painel, sidebar, topbar | `--text` ~11:1 (AAA) |
| `--surface-2` | #13294D | Superficie elevada: linha de tabela ativa, sub-card, dropdown | `--text` ~10:1 (AAA) |
| `--surface-glass` | rgba(13,43,82,.55) + blur(12px) | Modal, overlay, command palette, popover | `--text` >7:1 sobre navy (AA) |
| `--primary` | #0066FF | Cor de marca Empresa: CTA, estado ativo, links, foco | branco sobre #0066FF ~3.9:1 (AA p/ texto grande/UI) |
| `--primary-hover` | #1F78FF | Hover de elementos primarios | — |
| `--primary-active` | #0052CC | Pressionado/ativo; **usar p/ texto normal AA sobre claro** | branco sobre #0052CC ~5.9:1 (AA texto normal) |
| `--primary-soft` | rgba(0,102,255,.12) | Fundo suave de chip/badge/selecao leve azul | `--text`/`--primary` legivel sobre navy |
| `--accent` | #00F2FE | Assinatura Master, KPI-heroi, icones, linha de grafico | ciano sobre #020617 ~13:1 (AAA p/ numeros/icones) |
| `--accent-strong` | #00C2CB | Ciano para areas que precisam de mais corpo/borda | ~9:1 sobre navy (AAA) |
| `--success` | #10B981 | Base saudavel, entregue, conectado | ~7.5:1 sobre #020617 (AA) |
| `--warning` | #F59E0B | Atencao necessaria, reputacao em observacao | ~9:1 sobre #020617 (AAA) |
| `--danger` | #EF4444 | Reputacao em risco, erro, falha de envio | ~4.7:1 sobre #020617 (AA UI; usar label) |
| `--danger-hover` | #DC2626 | Hover de botao/acao destrutiva | branco sobre #DC2626 ~5.3:1 (AA) |
| `--danger-active` | #B91C1C | Pressionado de acao destrutiva | branco sobre #B91C1C ~7:1 (AA) |
| `--info` | #3B82F6 | Informativo, dica, estado neutro de sistema | ~5.2:1 sobre #020617 (AA) |
| `--text` | #F8FAFC | Texto primario, titulos, numeros | ~17:1 (AAA) |
| `--text-secondary` | #94A3B8 | Texto de corpo secundario, descricoes, labels | ~7:1 sobre #020617 (AA) |
| `--text-muted` | #64748B | Placeholder, metadado, texto desabilitado, captions | ~4.6:1 sobre #020617 (AA p/ texto >=14px bold/UI) |
| `--border` | #1E2A44 | Borda padrao de card/input, separadores | — (nao-texto, >=3:1 vs surface) |
| `--border-strong` | #2B3A5C | Borda de input, divisao enfatica, foco neutro | — (>=3:1 vs surface) |
| `--hover` | rgba(0,102,255,.08) | Fundo de hover de linha/item de menu | sobreposto a surface |
| `--selection` | rgba(0,102,255,.30) | Selecao de texto, linha selecionada | sobreposto a surface |
| `--focus-ring` | rgba(0,102,255,.45) | Anel de foco (2px + offset) | >=3:1 vs fundo adjacente |

**Sequencia de grafico (frio -> quente, primary-led):** `#0066FF`, `#00F2FE`, `#3385FF`, `#10B981`, `#A855F7`, `#F59E0B`, `#EF4444`. Usar nesta ordem para series; reservar #EF4444/#F59E0B para series que representem risco/alerta sempre que possivel.

**Aneis de status (foco/realce):** `--ring-success` rgba(16,185,129,.45), `--ring-warning` rgba(245,158,11,.45), `--ring-danger` rgba(239,68,68,.45) — analogos ao `--focus-ring`, para validacao de campo e cards de status.

### Os 13 papeis de cor (canonicos)

Os tokens acima se organizam nos **13 papeis** exigidos no brief:

| # | Papel | Token(s) | Hex |
|---|---|---|---|
| 1 | Fundo principal | `--bg-base` | #020617 |
| 2 | Superficie / card | `--surface` (e `--bg-subtle`, `--surface-2`, `--surface-glass`) | #0D2B52 |
| 3 | Primaria (marca Empresa) | `--primary` (+ hover/active/soft) | #0066FF |
| 4 | Secundaria / destaque (marca Master) | `--accent` (+ strong) | #00F2FE |
| 5 | Sucesso | `--success` | #10B981 |
| 6 | Alerta | `--warning` | #F59E0B |
| 7 | Erro | `--danger` (+ hover/active) | #EF4444 |
| 8 | Informativo | `--info` | #3B82F6 |
| 9 | Texto principal | `--text` | #F8FAFC |
| 10 | Texto secundario | `--text-secondary` (+ `--text-muted`) | #94A3B8 |
| 11 | Borda | `--border` (+ strong) | #1E2A44 |
| 12 | Hover / selecao | `--hover`, `--selection` | rgba(0,102,255,.08 / .30) |
| 13 | Foco | `--focus-ring` (+ aneis de status) | rgba(0,102,255,.45) |

Cor de grafico = papel transversal (sequencia definida acima), nao conta como 1 dos 13.

### Estados de botao

Tokens exatos por variante. Altura padrao 40px (`h-10`), raio `rounded-lg`, peso `font-semibold`, foco = anel `--focus-ring` 2px + offset 2px em todas.

| Variante | Normal | Hover | Ativo (pressed) | Desabilitado | Carregando |
|---|---|---|---|---|---|
| **Primario** (`btn-primary`) | Fundo `fluxo-gradient` (#0066FF->#00F2FE), texto #FFFFFF, `shadow-fluxo` | `scale(1.02)`, `shadow-fluxo-lg`, brilho leve `glow` | `scale(.99)`, fundo solido `--primary-active #0052CC` | Fundo `--surface-2`, texto `--text-muted`, sem sombra, `cursor-not-allowed`, opacity .6 | Texto -> spinner ciano, mantem gradiente, `pulse-soft`, aria-busy |
| **Secundario** (`btn-secondary`) | Fundo transparente, borda `--border-strong`, texto `--text` | Borda `--primary/60`, fundo `--hover`, texto `--text` | Fundo `--primary-soft`, borda `--primary` | Borda `--border`, texto `--text-muted`, opacity .6 | Spinner `--primary`, label esmaecido |
| **Ghost** (`btn-ghost`) | Sem fundo/borda, texto `--text-secondary` | Fundo `--hover`, texto `--text` | Fundo `--primary-soft`, texto `--primary` | Texto `--text-muted`, opacity .5 | Spinner `--text-secondary` |
| **Danger** (`btn-danger`) | Fundo `--danger #EF4444`, texto #FFFFFF | Fundo `#DC2626` (danger strong), `scale(1.02)`, `--ring-danger` | `scale(.99)`, fundo `#B91C1C` | Fundo `--surface-2`, texto `--text-muted`, opacity .6 | Spinner branco, `pulse-soft`, confirmacao bloqueada |

Notas: botao Master/operador pode usar variante primaria com gradiente puxando mais ciano (`--accent`); manter texto branco semibold. Em qualquer botao com fundo azul/ciano onde haja **texto pequeno normal**, garantir AA usando `--primary-active #0052CC` (ratio ~5.9:1) em vez de #0066FF.

**Nota de acessibilidade (obrigatoria):** contraste minimo WCAG **AA** (4.5:1 texto normal, 3:1 texto grande/UI/grafismo). `--text` sobre `--bg-base` ~17:1; `--text-secondary` ~7:1 (corpo ok); `--text-muted` apenas para metadado/placeholder. **Ciano puro nunca em texto pequeno** sobre navy claro — ciano so para numeros grandes, icones e acentos. **Status nunca so por cor:** sempre icone + label ("Base saudavel" + check verde, "Reputacao em risco" + alerta vermelho). Foco sempre visivel (anel `--focus-ring` 2px + offset). Todo input com label associado; navegacao completa por teclado.

## 3. Design System — Tipografia

**Familias:** display = **Poppins** (titulos, KPIs, hero; alt **Montserrat** quando Poppins indisponivel) · corpo/UI = **Inter** (texto, tabelas, labels, botoes) · valores tecnicos (registros DNS, SPF/DKIM, IDs, chaves) = **mono** `ui-monospace`. Fallback global: `system-ui, sans-serif`.

`font-display: swap` em todas; pesos carregados: Poppins 600/700, Inter 400/500/600, mono 400/500.

| Papel | Familia | Tamanho (rem / px) | Clamp responsivo | Peso | Line-height | Tracking |
|---|---|---|---|---|---|---|
| **H1** (titulo de pagina / hero) | Poppins | 2.25rem / 36px | `clamp(1.75rem, 1.2rem + 2.2vw, 2.5rem)` | 700 | 1.1 | -0.02em |
| **H2** (secao) | Poppins | 1.5rem / 24px | `clamp(1.375rem, 1.1rem + 1vw, 1.75rem)` | 600 | 1.2 | -0.01em |
| **H3** (titulo de card/bloco) | Poppins | 1.125rem / 18px | `clamp(1.0625rem, 1rem + .4vw, 1.25rem)` | 600 | 1.3 | -0.01em |
| **Texto de card** (corpo em card) | Inter | 0.9375rem / 15px | — | 400 | 1.55 | 0 |
| **Texto de tabela** (celula) | Inter | 0.875rem / 14px | — | 400 (500 em col-chave) | 1.45 | 0 |
| **Texto de botao** | Inter | 0.875rem / 14px | — | 600 | 1 | 0.01em |
| **Texto auxiliar** (descricao/caption) | Inter | 0.8125rem / 13px | — | 400 | 1.5 | 0 |
| **Label** (campo/coluna/badge) | Inter | 0.75rem / 12px | — | 500/600 | 1.4 | 0.04em (uppercase opcional) |
| **Numero / KPI** (valor-heroi) | Poppins | 2.5rem / 40px | `clamp(2rem, 1.5rem + 2vw, 3rem)` | 700 | 1 | -0.02em (tabular-nums) |
| **KPI secundario** (numero menor) | Poppins | 1.5rem / 24px | — | 600 | 1.05 | -0.01em (tabular-nums) |
| **KPI compacto** (card denso) | Poppins | 1.75rem / 28px | — | 700 | 1.05 | -0.02em (tabular-nums) |
| **Mono / DNS** (registro/chave) | ui-monospace | 0.8125rem / 13px | — | 400 | 1.6 | 0 |

**Justificativa (tecnologia + clareza):** Poppins em titulos e KPIs traz geometria limpa e moderna — sensacao de produto de tecnologia, nao de agencia — e da peso visual aos numeros que decidem (com `tabular-nums` para alinhamento de colunas de metricas). Inter no corpo e em tabelas e otimizado para telas e densidade: altura-x generosa, legibilidade em 13-15px, leitura confortavel em paineis longos. Mono em valores DNS/SPF/DKIM/chaves elimina ambiguidade de caracteres (0/O, 1/l/I) e sinaliza "isto e um valor tecnico para copiar". O tracking levemente negativo nos titulos densifica e moderniza; o tracking positivo em labels uppercase organiza o cromo sem competir com o conteudo.

## 4. Design System — Grid & espacamento

**Escala de espacamento (base 4px).** Tokens Tailwind padrao; usar a escala, nunca valores avulsos.

| Token | px | rem | Uso tipico |
|---|---|---|---|
| `space-0.5` | 2 | 0.125 | hairline/ajuste otico |
| `space-1` | 4 | 0.25 | gap icone-texto, padding de badge |
| `space-2` | 8 | 0.5 | gap interno compacto |
| `space-3` | 12 | 0.75 | padding de input, gap de form-row |
| `space-4` | 16 | 1 | padding base, gap de lista |
| `space-5` | 20 | 1.25 | — |
| `space-6` | 24 | 1.5 | padding interno de card, gap entre cards |
| `space-8` | 32 | 2 | gap de secao, margem de bloco |
| `space-10` | 40 | 2.5 | — |
| `space-12` | 48 | 3 | espaco entre secoes maiores |
| `space-16` | 64 | 4 | respiro de pagina / hero |

**Grid responsivo:**

| Breakpoint | Largura | Colunas | Container max | Gutter | Margem lateral |
|---|---|---|---|---|---|
| Desktop (`lg`/`xl` >=1024px) | >=1280px | 12 | 1280px (`max-w-7xl`) | 24px (`gap-6`) | 32px |
| Tablet (`md` 768-1023px) | 768-1023 | 8 | 100% fluido | 20px (`gap-5`) | 24px |
| Mobile (`<md` <768px) | <768 | 4 | 100% fluido | 16px (`gap-4`) | 16px |

**Valores concretos de componente:**

| Elemento | Valor | Token / classe |
|---|---|---|
| Gap entre cards | 24px | `gap-6` |
| Padding interno de card | 24px (mobile 16px) | `p-6` / `p-4` |
| Altura de botao | 40px (sm 32px, lg 48px) | `h-10` / `h-8` / `h-12` |
| Padding horizontal de botao | 16px (sm 12px, lg 24px) | `px-4` / `px-3` / `px-6` |
| Altura de input | 40px (sm 36px) | `h-10` / `h-9` |
| Padding de input | 12px / 12px | `px-3 py-3` |
| Raio sm | 8px | `rounded-lg` (inputs, botoes, chips) |
| Raio md | 12px | `rounded-xl` (sub-cards, dropdowns) |
| Raio lg | 16px | `rounded-2xl` (cards, paineis) |
| Raio 2xl | 24px | `rounded-3xl` (hero/destaque) |
| Raio full | 9999px | `rounded-full` (avatar, badge, toggle) |
| Sombra sm | 0 1px 2px rgba(2,6,23,.4) | `shadow-sm` (sutil, superficies internas) |
| Sombra md | 0 4px 12px rgba(2,6,23,.5) | `shadow-md` (dropdown, popover) |
| Sombra fluxo | 0 4px 14px rgba(0,102,255,.25) | `shadow-fluxo` (CTA, card ativo) |
| Sombra fluxo-lg | 0 10px 40px -5px rgba(0,102,255,.35) | `shadow-fluxo-lg` (modal, hover de CTA) |
| Separador | 1px `--border #1E2A44` | `border-t border-[#1E2A44]` |
| Separador enfatico | 1px `--border-strong #2B3A5C` | `border-[#2B3A5C]` |
| Sidebar expandida | 256px | `w-64` |
| Sidebar colapsada | 72px | `w-[72px]` (so icones) |
| Altura da topbar | 64px | `h-16` |
| Largura max de conteudo de leitura | 720px | `max-w-[720px]` (docs/config) |
| Largura de modal padrao | 560px | `max-w-[560px]` |

**Notas de layout:** cards usam `rounded-2xl` + `border --border` + `shadow-lg`, hover `border --primary/30` + `-translate-y-1`. A sidebar (`--surface`) tem borda direita `--border`; a topbar (`--surface`, `h-16`) tem borda inferior `--border` (Empresa) ou faixa/glow `--accent-strong` (Master). Espacamento de pagina: container `max-w-7xl mx-auto px-8` (desktop), reduzindo para `px-4` no mobile. Ritmo vertical entre blocos = `space-8` (32px); dentro de card = `space-6` (24px).

---

## 5. Componentes (biblioteca)

Princípios transversais (valem para TODOS os componentes):
- **Raios:** `rounded-2xl` (cards/modais/drawer), `rounded-lg` (inputs/botões/badges/menus), `rounded-full` (avatar/pílulas/dot de status).
- **Alturas de controle:** sm 32px / md 40px (padrão) / lg 48px. Botão, Input, Select e Date picker compartilham a mesma altura em uma mesma linha.
- **Focus-ring único (regra rígida):** `outline: 2px solid var(--focus-ring); outline-offset: 2px;` em TUDO que recebe foco (Tailwind: `focus-visible:ring-2 focus-visible:ring-fluxo-500/45 focus-visible:ring-offset-2 focus-visible:ring-offset-bg-base`). Variantes de risco trocam por `--ring-success/warning/danger`.
- **Superfícies:** `--surface` (#0D2B52) para cards em repouso, `--surface-2` (#13294D) para linha hover/elevação, `--surface-glass` SÓ em overlays (modal, drawer, dropdown, tooltip, toast).
- **Hover de card:** `border-fluxo-500/30` + `-translate-y-1` + `shadow-fluxo-lg`, transição 150ms.
- **Status nunca só por cor:** sempre ícone + label + (quando aplicável) dot.
- **Master vs Empresa:** Master usa `--accent` (#00F2FE) como cor de acento/selo; Empresa usa a cor do tenant (fallback `--primary`). Diferença concentrada em Sidebar, Topbar e Dropdown de empresa; o resto da biblioteca é idêntico.

---

### 5.1 Sidebar

Navegação vertical persistente. Colapsável (256px → 72px). Item ativo precisa ser inequívoco.

**Anatomia:** logo/marca (topo) → grupos de navegação (label + itens) → bloco inferior (ambiente atual + colapsar). Cada item = ícone 20px + label + (opcional) badge numérico.

**Tokens/classes:**
- Container: `bg-[--bg-subtle]` (#0A1F3D), borda direita `border-[--border]`, largura `w-64` / colapsada `w-[72px]`.
- Item repouso: `text-[--text-secondary]`, ícone `text-[--text-muted]`, `rounded-lg`, altura 40px.
- Item hover: `bg-[--hover]` + `text-[--text]`.
- **Item ativo (muito claro):** `bg-[--primary-soft]` (rgba 0,102,255,.12) + barra lateral esquerda 3px `bg-fluxo-500` (Master: `bg-accent-500`) + `text-[--text]` + ícone na cor de acento do ambiente + `font-medium`.
- Label de grupo: `text-[10px] uppercase tracking-wider text-[--text-muted]`.

**Estados/variantes:**
- **Master:** selo/cor de acento `--accent` (ciano), badge "MASTER" no topo, item ativo com barra ciano.
- **Empresa:** acento = cor do tenant, dot da cor do tenant ao lado do logo.
- Colapsada: só ícones, label vira `Tooltip` à direita no hover. Item ativo mantém barra de 3px.
- Mobile: vira off-canvas (Drawer da esquerda), abre via hambúrguer da Topbar.

```
EXPANDIDA (Master)            COLAPSADA
┌───────────────────────┐    ┌──────┐
│ ◧ Fluxo  [MASTER]     │    │ ◧    │
│ ─────────────────────  │    ├──────┤
│ PRINCIPAL             │    │      │
│▍◰ Visão geral         │←   │▍◰    │ ← ativo (barra 3px)
│ ◳ Empresas       (12) │    │ ◳ ¹² │
│ ◵ Reputação           │    │ ◵    │
│ ENVIO                 │    │      │
│ ◷ Campanhas           │    │ ◷    │
│ ⟳ Automações          │    │ ⟳    │
│ ─────────────────────  │    ├──────┤
│ ◧ Ambiente: Fluxo     │    │ «    │ ← colapsar
│ « Recolher            │    └──────┘
└───────────────────────┘
```

---

### 5.2 Topbar

Barra superior fixa, 64px. Contexto + busca global + ações.

**Anatomia:** [hambúrguer mobile] → Breadcrumb / título da página → Busca global (centro) → ações à direita (notificações, ajuda, avatar/menu). No Master, à direita-centro fica o **Dropdown de empresa**.

**Tokens/classes:**
- Container: `h-16 bg-[--bg-base]/80 backdrop-blur-md border-b border-[--border] sticky top-0 z-40`.
- Ícones de ação: `text-[--text-secondary] hover:text-[--text]`, alvo 40px, `rounded-lg`.
- Notificação com pendência: dot `bg-danger` no canto do ícone.
- **Master:** fina régua de acento no topo `h-0.5 bg-accent-500` + Dropdown de empresa visível.
- **Empresa:** régua na cor do tenant; sem dropdown de troca (mostra só o nome/selo da empresa, não-clicável).

```
┌──────────────────────────────────────────────────────────────┐
│ ☰  Campanhas › Nova                 [⌕ Buscar… ⌘K]   ▾Empresa ⓘ ◉│
└──────────────────────────────────────────────────────────────┘
```

---

### 5.3 Card de métrica (KPI + delta + sparkline)

KPI premium: número grande, delta com direção, sparkline de tendência.

**Anatomia:** label (topo) → valor (display, grande) → delta (seta + %, com cor de status) → sparkline (rodapé) → ícone temático (canto sup. dir., sutil).

**Tokens/classes:**
- Card base + hover de card (regra global).
- Label: `text-sm text-[--text-secondary]`.
- Valor: `font-display text-3xl text-[--text]`; números de destaque podem usar `text-accent-500` quando isolados.
- Delta positivo: `text-success` + `▲`; negativo: `text-danger` + `▼`; neutro: `text-[--text-muted]` + `–`. Sempre seta + sinal (nunca só cor).
- Sparkline: stroke `--primary`, área `--primary-soft`.

**Estados:** loading → `Skeleton` (shimmer). Sem dado → traço `–` + microcopy "Sem dados ainda". Meta atingida → micro-badge `success`.

```
┌────────────────────────────┐
│ Taxa de abertura        ◷  │
│ 38,2%                       │
│ ▲ 4,1%  vs. 30d            │  (success)
│ ▁▂▃▅▆▇▆▅  ─────────────     │
└────────────────────────────┘
```

---

### 5.4 Card de alerta

Comunica risco/atenção/info com ação. Reforça a voz "Reputação em risco".

**Anatomia:** ícone de severidade (esq.) → título + descrição → ação (botão/link) → dismiss opcional.

**Tokens/classes:**
- Estrutura de card; borda-esquerda 3px na cor da severidade.
- danger: `border-l-danger`, ícone `text-danger`, fundo `bg-[--danger]/8`. warning: `--warning`. info: `--info`. success: `--success`.
- Título `font-medium text-[--text]`, descrição `text-[--text-secondary]`.

**Variantes/microcopy:** "Reputação em risco" (danger), "Atenção necessária" (warning), "Base saudável" (success), "IA recomenda" (info, ícone faísca). Sempre ícone + label.

```
┌─────────────────────────────────────────┐
│ ⚠  Reputação em risco                     │
│    Bounce em 6,2% no domínio mkt.acme.com │
│                       [ Ver detalhes → ]  │
└─────────────────────────────────────────┘
  ↑ border-l-warning
```

---

### 5.5 Card de campanha

Resumo de uma campanha na listagem em grade.

**Anatomia:** linha de topo (nome + `Badge` de status + kebab) → assunto (1 linha, truncado) → métricas inline (enviados / abertura / clique) → rodapé (data/agendamento + mini-sparkline).

**Tokens/classes:** card + hover global; nome `font-medium`; assunto `text-[--text-secondary] truncate`; métricas em grid de 3 com label `text-[--text-muted]`.

**Estados:** rascunho (CTA "Continuar edição"), agendada (mostra data + countdown), enviando (barra de progresso `--primary`/`--accent` + `pulse-soft`), enviada (métricas vivas), pausada (overlay sutil + CTA "Retomar"), bloqueada (cadeado + `Badge` danger, ações limitadas).

```
┌───────────────────────────────────────┐
│ Black Friday — Aquecimento  ●Enviando ⋮│
│ "Sua oferta exclusiva começa agora"     │
│  Enviados   Abertura   Clique           │
│  12.480     34,1%      5,2%             │
│  ▓▓▓▓▓▓▓░░░ 68%   ▁▂▃▅▆▇  · há 2 min    │
└───────────────────────────────────────┘
```

---

### 5.6 Card de automação

Representa um fluxo/automação (gatilho → passos → status motor).

**Anatomia:** nome + toggle ligado/desligado (topo) → resumo do gatilho ("Quando lead entra…") → mini-fluxo (chips de passos) → métrica (em curso / concluídos) → kebab.

**Tokens/classes:** card + hover; toggle ON `bg-fluxo-500`, knob branco, `focus-ring`; chips de passo `bg-[--surface-2] border-[--border] rounded-lg text-xs`; conector `›`.

**Estados:** ativa (toggle ON, dot `success` "Motor ligado"), pausada (toggle OFF, `--text-muted`), rascunho (sem gatilho, CTA "Configurar gatilho"), erro (chip do passo com `--danger` + label). Microcopy do toggle: "Ligar motor" / "Motor ligado".

```
┌───────────────────────────────────────┐
│ Qualificação IA 24/7        [●▬ Ligado]│
│ Quando: lead entra na lista "Site"     │
│ [Espera 5m] › [IA qualifica] › [E-mail]│
│ ● Motor ligado · 320 em curso          │
└───────────────────────────────────────┘
```

---

### 5.7 Tabela (densa / zebra / sticky header / sort / seleção)

Tabela de dados de alta densidade (contatos, eventos, logs).

**Anatomia:** header sticky → linhas zebra → coluna de seleção (checkbox) → coluna de ações (kebab) → footer com `Paginação`.

**Tokens/classes:**
- Header: `sticky top-0 z-10 bg-[--bg-subtle] text-[--text-secondary] text-xs uppercase tracking-wide border-b border-[--border-strong]`.
- Linhas: altura densa 44px; zebra par `bg-transparent`, ímpar `bg-white/[.02]`; hover `bg-[--hover]`; selecionada `bg-[--primary-soft]` + borda-esq `--primary`.
- Sort: label clicável + caret `▲/▼`; ativo `text-[--text]`, demais `--text-muted`.
- Seleção: checkbox no header (selecionar tudo) + barra de ações em massa flutuante quando há seleção.
- Borda de células `--border`; mono (`font-mono`) para valores técnicos/DNS.

**Estados:** vazio → `Empty state` embutido; loading → linhas `Skeleton`; erro → linha de aviso. Foco de teclado navega linhas (setas) com `focus-ring`.

```
┌──┬───────────────┬───────────┬──────────┬───┐
│☑ │ CONTATO  ▲     │ STATUS    │ ABERTURA │ ⋮ │ ← sticky
├──┼───────────────┼───────────┼──────────┼───┤
│☑ │ ana@acme.com  │ ✓ Enviada │ 41%      │ ⋮ │ ← selecionada
│☐ │ rui@acme.com  │ ⏳ Fila   │ —        │ ⋮ │
│☐ │ leo@acme.com  │ ✕ Bounce  │ —        │ ⋮ │
└──┴───────────────┴───────────┴──────────┴───┘
[ 3 selecionados · Exportar · Remover ]   ‹ 1 2 3 ›
```

---

### 5.8 Filtros

Refinamento de listas/tabelas. Pílulas + painel.

**Anatomia:** linha de pílulas de filtro ativas (removíveis) + botão "Filtros" que abre painel/`Drawer` com campos.

**Tokens/classes:** pílula ativa `bg-[--primary-soft] border-fluxo-500/30 text-[--text] rounded-full text-xs` com `×`; botão "Filtros" = `Botão` ghost com badge de contagem; campos reusam `Input`/`Select`/`Date picker`.

**Estados:** sem filtros (botão neutro), com filtros (badge numérico `bg-fluxo-500`), "Limpar tudo" como link. 

```
[ Status: Enviada × ] [ Período: 30d × ] [+ Filtros ②]  · Limpar
```

---

### 5.9 Busca (global + local)

**Global (⌘K):** `bg-[--surface-glass] backdrop-blur-md`, modal centrado, resultados agrupados (Empresas, Campanhas, Contatos, Ações). Input grande `h-12`, ícone `⌕`, atalho `⌘K` visível na Topbar. Navegação por setas + Enter, `focus-ring`.

**Local:** input compacto `h-10` acima de tabela/lista; filtra em tempo real; ícone limpar `×`.

**Tokens/classes:** input base (ver 5.11); resultado ativo `bg-[--primary-soft]`; categoria label `--text-muted`. Vazio → "Nada encontrado para '…'".

```
┌──────────────────────────────────────┐
│ ⌕  Buscar empresas, campanhas…   ⌘K   │
├──────────────────────────────────────┤
│ EMPRESAS                              │
│ ▸ Acme Ltda                           │ ← ativo
│ CAMPANHAS                             │
│ ▸ Black Friday — Aquecimento          │
└──────────────────────────────────────┘
```

---

### 5.10 Botões (5 estados)

Altura padrão 40px (`h-10`), `rounded-lg`, `font-medium`, transição 150ms. **Os 5 estados em todas as variantes:** default · hover · active · focus · disabled (+ loading).

| Variante | Default | Hover | Active | Focus | Disabled |
|---|---|---|---|---|---|
| **Primário** | gradient `from-fluxo-500 to-accent-500`, texto branco, `shadow-fluxo` | `scale-[1.02]` + `shadow-fluxo-lg` | `scale-[0.99]`, `--primary-active` | + `focus-ring` | `opacity-50 cursor-not-allowed`, sem gradient |
| **Secundário** | `bg-[--surface-2] border-[--border-strong] text-[--text]` | `border-fluxo-500/40 bg-[--hover]` | `bg-[--primary-soft]` | + `focus-ring` | `opacity-50` |
| **Ghost** | transparente, `text-[--text-secondary]` | `bg-[--hover] text-[--text]` | `bg-[--primary-soft]` | + `focus-ring` | `opacity-40` |
| **Danger** | `bg-danger text-white` (texto branco semibold p/ AA) | `bg-[#DC2626]` | `bg-[#B91C1C]` | + `ring-danger` | `opacity-50` |

- **Loading:** spinner + label "Enviando…", largura travada, `aria-busy`. Microcopy de ação: "Ligar motor", "Pronto para envio".
- Ícone+texto: gap 8px; icon-only = quadrado 40px + `aria-label`.

```
[ ▸ Ligar motor ]  [ Cancelar ]  ⌁Ghost  [ ⌫ Excluir ]
  primário          secundário    ghost     danger
```

---

### 5.11 Input

**Anatomia:** label (acima) → campo → hint/erro (abaixo). Opcional: ícone à esquerda, sufixo à direita.

**Tokens/classes:** `h-10 bg-[--surface]/60 border border-[--border-strong] rounded-lg px-3 text-[--text] placeholder:text-[--text-muted]`; focus `focus:border-fluxo-500 focus-visible:ring-2 focus-visible:ring-fluxo-500/20`; label `text-sm text-[--text-secondary]`.

**Estados:** default · focus · filled · disabled (`opacity-50`) · **erro** (`border-danger` + `ring-danger` + texto `text-danger` com ícone ⚠ + mensagem) · sucesso (`border-success` + ✓). Erro/sucesso sempre com ícone, não só borda.

```
Nome da campanha
┌────────────────────────────┐
│ Black Friday               │
└────────────────────────────┘
⚠ Já existe uma campanha com esse nome   (erro)
```

---

### 5.12 Select

Mesma moldura do Input + caret `▾`. Menu = popover `--surface-glass` `rounded-lg border-[--border]`, opção ativa `bg-[--primary-soft]`, opção hover `bg-[--hover]`, selecionada com `✓`. Suporta busca interna quando >8 itens. Estados idênticos ao Input (incl. erro/disabled). Multi-select usa pílulas (como Filtros).

```
Status        ┌───────────────┐
[ Enviada ▾ ] │ ✓ Enviada     │
              │   Agendada    │
              │   Rascunho    │
              └───────────────┘
```

---

### 5.13 Date picker

Trigger = `Input` com ícone calendário. Popover `--surface-glass`. Calendário: dia hoje `border-fluxo-500`, selecionado `bg-fluxo-500 text-white`, range `bg-[--primary-soft]`, fora do mês `--text-muted`. Presets rápidos (Hoje, 7d, 30d, Mês). Navegação por teclado nas células (`focus-ring`). Estados: erro = `--ring-danger` no trigger + mensagem abaixo; desabilitado = `opacity-50 cursor-not-allowed`; range selecionado realça início/fim (`bg-fluxo-500`) e o intervalo (`bg-[--primary-soft]`).

```
┌──────────────────────────┐
│ ‹  Junho 2026          › │
│ D  S  T  Q  Q  S  S      │
│       1  2  3  4  5      │
│ ... 22 [23] 24 ...        │ ← hoje
│ Presets: Hoje · 7d · 30d │
└──────────────────────────┘
```

---

### 5.14 Modal

Diálogo centrado para foco/confirmação. Overlay `bg-bg-base/70 backdrop-blur-sm`.

**Anatomia:** header (título + `×`) → corpo → footer (ações: primário à direita, secundário à esq.).

**Tokens/classes:** painel `bg-[--surface-glass] backdrop-blur-md border border-[--border] rounded-2xl shadow-fluxo-lg`, largura `max-w-lg`, `fade-in-scale`. Foco preso (focus trap), `Esc` fecha, foco inicial no primeiro campo/ação.

**Variantes:** confirmação destrutiva (ícone danger, botão `danger`, exige digitar nome para confirmar quando crítico), formulário, informativo.

```
┌─────────────────────────────────────┐
│ Excluir campanha?               ✕   │
├─────────────────────────────────────┤
│ Esta ação não pode ser desfeita.    │
│ Digite "Black Friday" para confirmar│
│ ┌─────────────────────────────────┐ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│            [ Cancelar ] [ Excluir ] │
└─────────────────────────────────────┘
```

---

### 5.15 Drawer lateral

Painel deslizante (direita: detalhes/edição; esquerda: nav mobile). Largura 420px (mobile: full).

**Tokens/classes:** `bg-[--surface-glass] backdrop-blur-md border-l border-[--border] shadow-fluxo-lg`, slide-in 200ms, overlay clicável fecha, `Esc` fecha, focus trap. Header sticky (título + `×`), footer sticky para ações.

**Uso:** detalhe de contato, edição rápida, painel de Filtros, nav mobile (à esquerda).

```
                   ┌──────────────────┐
                   │ Detalhe contato ✕│
                   │ ────────────────  │
   (overlay)       │ ana@acme.com     │
   bg-base/70      │ Status: Enviada  │
                   │ Aberturas: 3     │
                   │ ────────────────  │
                   │ [ Editar ]       │
                   └──────────────────┘
```

---

### 5.16 Toast

Notificação efêmera, canto inferior direito, empilhável, auto-dismiss 5s (erro fica até fechar).

**Tokens/classes:** `bg-[--surface-glass] backdrop-blur-md border-l-2 rounded-lg shadow-fluxo-lg`, `fade-in-scale`; ícone + título + descrição curta + `×`. Borda-esquerda na cor da severidade.

**Variantes (sempre ícone+label):**
- Sucesso: `border-l-success` ✓ — "Campanha agendada".
- Erro: `border-l-danger` ✕ — "Falha no envio" (persistente + ação "Tentar de novo").
- Aviso: `border-l-warning` ⚠ — "Reputação em risco".

```
┌────────────────────────────┐
│✓ Campanha agendada       ✕ │  success
│  Disparo em 23/06 09:00     │
└────────────────────────────┘
```

---

### 5.17 Badge de status

Pílula `rounded-full px-2 h-6 text-xs font-medium`, **sempre dot/ícone + label**. Fundo = cor `/12`, texto/dot = cor cheia.

| Estado | Cor | Ícone | Label |
|---|---|---|---|
| Rascunho | `--text-muted` | ✎ | Rascunho |
| Agendada | `--info` | ⏱ | Agendada |
| Enviando | `--accent` | ◐ (`pulse-soft`) | Enviando |
| Enviada | `--success` | ✓ | Enviada |
| Pausada | `--warning` | ⏸ | Pausada |
| Bloqueada | `--danger` | ⊘ | Bloqueada |

**Saúde de domínio:** ● Saudável (`--success`) · ● Atenção (`--warning`) · ● Crítico (`--danger`) — "Base saudável" / "Atenção necessária" / "Reputação em risco".
**Risco (IA):** Baixo (success) · Médio (warning) · Alto (danger), prefixo ícone escudo.

```
✎ Rascunho   ⏱ Agendada   ◐ Enviando   ✓ Enviada   ⏸ Pausada   ⊘ Bloqueada
● Base saudável     ● Atenção necessária     ● Reputação em risco
```

---

### 5.18 Avatar

`rounded-full`, tamanhos 24/32/40px. Imagem ou iniciais sobre `--surface-2` com `text-[--text]`. Empresa: cor de fundo = cor do tenant. Status dot opcional (online `--success`). Grupo: stack com sobreposição -8px + contador `+N`.

```
(◉)  (◉)(◉)(◉) +3    [AC] ← iniciais tenant
```

---

### 5.19 Dropdown de empresa (troca de tenant — SÓ Master)

Seletor de tenant na Topbar (Master). Comuta todo o contexto.

**Anatomia:** trigger (avatar tenant + nome + `▾`) → popover com busca + lista de empresas (avatar + nome + saúde) + "Voltar ao ambiente Fluxo".

**Tokens/classes:** popover `--surface-glass` `rounded-lg border-[--border] shadow-fluxo-lg`; item ativo `bg-[--primary-soft]` + `✓`; busca interna (reusa 5.9 local); cada item mostra `Badge` de saúde de domínio.

**Estado:** ambiente Master (acento ciano) vs ambiente Empresa selecionado (acento = cor do tenant; Topbar troca de régua). Microcopy: "Trocar empresa", "Você está em: Acme".

```
[ (AC) Acme Ltda ▾ ]
   ┌────────────────────────────┐
   │ ⌕ Buscar empresa…          │
   │ ✓ (AC) Acme   ● Saudável   │ ← ativo
   │   (NB) Nubex  ● Atenção    │
   │   (ZP) Zappy  ● Crítico    │
   │ ───────────────────────────│
   │ ◧ Voltar ao ambiente Fluxo │
   └────────────────────────────┘
```

---

### 5.20 Breadcrumb

Trilha de contexto na Topbar. Segmentos `text-[--text-muted]`, separador `›`, atual `text-[--text]`. Clicável exceto o atual. Em Master, prefixo opcional com empresa: `Acme › Campanhas › Nova`.

```
Empresas › Acme › Campanhas › Nova
(muted)              ›        (text)
```

---

### 5.21 Tabs

Navegação intra-página. Linha de abas com indicador inferior.

**Tokens/classes:** aba ativa `text-[--text]` + sublinhado 2px `bg-fluxo-500`; inativa `text-[--text-secondary] hover:text-[--text]`; container `border-b border-[--border]`. `focus-ring` por aba; setas navegam (role=tablist).

```
 Visão geral │ Conteúdo │ Destinatários │ Relatório
 ──────────                                          ← indicador (ativa)
```

---

### 5.22 Empty state

Estado vazio com orientação e CTA — nunca tela morta.

**Anatomia:** ícone/ilustração sutil (`--text-muted`) → título → texto curto → CTA primário.

**Tokens/classes:** centralizado, ícone em círculo `bg-[--surface-2]`; título `font-medium text-[--text]`; texto `text-[--text-secondary]`; CTA = `Botão` primário.

**Microcopy por contexto:** sem campanhas → "Nenhuma campanha ainda" / "Crie a primeira e ligue o motor" [+ Nova campanha]; sem resultados de busca/filtro → "Nada por aqui" + "Limpar filtros".

```
        ┌────┐
        │ ◷  │
        └────┘
   Nenhuma campanha ainda
 Crie a primeira e ligue o motor
      [ + Nova campanha ]
```

---

### 5.23 Loading skeleton

Placeholder com shimmer durante carregamento. Espelha o layout final (mesmos raios/alturas).

**Tokens/classes:** blocos `rounded-lg`/`rounded-2xl` com gradiente shimmer `#0D2B52 → #13294D` em loop (`animate-pulse`/shimmer). Texto = barras de 2-3 larguras variadas; KPI = bloco grande + barra; tabela = N linhas de células. `aria-busy="true"`, sem conteúdo "fantasma" enganoso.

```
┌────────────────────────────┐
│ ▭▭▭▭                        │
│ ▭▭▭▭▭▭▭▭▭▭                  │
│ ▭▭▭   ▭▭▭▭▭                 │
└────────────────────────────┘  (shimmer)
```

---

### 5.24 Página de erro (404 / 500 / sem permissão)

Tela cheia centrada sobre `--bg-base` com `fluxo-gradient-dark` sutil ao fundo.

**Anatomia:** código grande (display, `text-accent-500`) → título → explicação → ações (Voltar / Ir ao início / Falar com suporte).

**Variantes:**
- **404:** "Página não encontrada" — "Esse caminho não existe no motor." [Voltar] [Início].
- **500:** "Algo travou no motor" — "Já fomos avisados. Tente novamente." [Recarregar] [Suporte]. Ícone `--danger`.
- **403 / sem permissão:** "Acesso restrito" — "Você não tem acesso a este ambiente." [Voltar] — ícone cadeado `--warning`. (Master: oferece "Trocar empresa".)

```
            404
   Página não encontrada
 Esse caminho não existe no motor.
     [ Voltar ]  [ Início ]
```

---

### 5.25 Tooltip

Microajuda no hover/focus. `--surface-glass` `rounded-lg`, `text-xs text-[--text]`, seta 6px, sombra `shadow-fluxo-lg`, delay 300ms, `fade-in`. Aparece também no foco de teclado (acessível). Usado em ícones icon-only, sidebar colapsada, e labels técnicos. Máx ~240px de largura.

```
        ┌─────────────────┐
        │ Reenviar campanha│
        └────────▾────────┘
            [⟳]  ← alvo
```

---

### 5.26 Menu de ações rápidas (kebab / quick actions)

**Kebab (⋮):** abre `Dropdown` (`--surface-glass`, `rounded-lg`, `shadow-fluxo-lg`) com itens (ícone + label); destrutivos (`text-danger`) separados por divisória no rodapé. Hover `bg-[--hover]`, foco `focus-ring`, navegação por setas, `Esc` fecha.

**Quick actions (hover de linha/card):** cluster de ícones que aparece no hover (`Editar`, `Duplicar`, `⋮`), cada um com `Tooltip` + `aria-label`. Em mobile, sempre o kebab (sem hover).

```
[⋮]
 ┌────────────────────┐
 │ ✎ Editar           │
 │ ⧉ Duplicar         │
 │ ⏸ Pausar           │
 │ ──────────────────  │
 │ 🗑 Excluir (danger) │
 └────────────────────┘
```

---

**Consistência (resumo de reuso):** todos os controles de uma linha compartilham altura (40px) e `rounded-lg`; todos os cards/overlays usam `rounded-2xl`; o `focus-ring` (`--focus-ring`, 2px + offset 2px) é idêntico em todo lugar; overlays (Modal, Drawer, Toast, Dropdown, Tooltip, Busca global) usam `--surface-glass` + `backdrop-blur`; status sempre ícone+label; Master = acento `--accent`, Empresa = cor do tenant — diferença concentrada em Sidebar/Topbar/Dropdown de empresa, biblioteca restante idêntica.

---

## 6. Estrutura geral & navegacao (Master x Empresa)

A plataforma opera em **dois ambientes distintos**, com a mesma fundacao visual (tema escuro premium sobre navy, tokens da marca) mas com sinalizacao clara de contexto para que ninguem confunda "onde estou e o que posso fazer".

### Os 2 ambientes

**Ambiente MASTER (Fluxo)** — o painel de quem opera a plataforma. Visao macro de todas as empresas, controle de planos, entregabilidade global, auditoria e aprovacoes. Selo **"Master Fluxo"** em ciano (`--accent #00F2FE`) sempre visivel. E o ponto de vista do "motor de vendas" inteiro: enxerga risco, volume e receita de todos os tenants.

**Ambiente EMPRESA (Tenant)** — o painel operacional do cliente. Escopo restrito aos dados da propria empresa: contatos, campanhas, automacoes, dominio de envio, relatorios. Barra de tenant em **azul Fluxo** (`--primary #0066FF`) com o nome da empresa atual. E onde se "liga o motor" no dia a dia.

> **Regra de ouro do contexto:** ambiente nunca e ambiguo. Master = acento ciano + selo. Empresa = barra azul + nome do tenant. Quando o Master "entra como suporte" numa empresa, os dois sinais coexistem (selo Master + banner de impersonacao) — ver secao 8.

### Diferenciacao visual do ambiente

| Sinal | Master (Fluxo) | Empresa (Tenant) |
|---|---|---|
| Selo/identidade | Pill **"Master Fluxo"** ciano: `bg-accent-500/15`, `text-accent-500`, `border border-accent-500/30`, icone raio (`bolt`) | Nome da empresa + avatar/logo do tenant |
| Barra de contexto (topo da sidebar) | Borda lateral esquerda `border-l-2 border-accent-500` | Borda lateral esquerda `border-l-2 border-primary` (`bg-fluxo-500`) |
| Troca de empresa | Disponivel (combo "Trocar empresa") | **Ausente** |
| Acento de foco/ativo no menu | `text-accent-500` + `bg-surface-2` | `text-fluxo-400` + `bg-surface-2` |
| Densidade | Mais densa (tabelas, mais KPIs) | Mais respiravel (operacao) |

O resto do shell (fundo `--bg-base`, surfaces, tipografia Poppins/Inter, sombras `shadow-fluxo`) e **identico** entre ambientes — a diferenca e o acento e o selo, nunca uma cor de fundo nova.

### Sidebar MASTER (itens exatos)

Agrupada para reduzir carga cognitiva. Largura `w-64` (expandida) / `w-[72px]` (colapsada, so icones + tooltip). Item ativo: `bg-surface-2` + `border-l-2 border-accent-500` + `text-accent-500`. Hover: `bg-[--hover]`.

```
GERAL
  · Visao Geral
EMPRESAS & PESSOAS
  · Empresas
  · Usuarios
ENVIO & SAUDE
  · Dominios
  · Entregabilidade
EXECUCAO
  · Campanhas
  · Automacoes
  · Templates Globais
INTELIGENCIA
  · Relatorios
  · Alertas
GOVERNANCA
  · Planos e Limites
  · Auditoria
  · Configuracoes
```

(Os labels exibidos sao exatamente: Visao Geral, Empresas, Usuarios, Dominios, Entregabilidade, Campanhas, Automacoes, Templates Globais, Relatorios, Alertas, Planos e Limites, Auditoria, Configuracoes. Os cabecalhos de grupo em `text-text-muted text-xs uppercase tracking-wide` sao organizacionais e nao clicaveis.)

### Sidebar EMPRESA (itens exatos)

Mesma mecanica de ativo/hover, mas acento azul (`border-l-2 border-primary`, `text-fluxo-400`).

```
OPERACAO
  · Dashboard
  · Contatos
  · Listas
  · Segmentos
ENVIO
  · Campanhas
  · Automacoes
  · Templates
  · Dominio de Envio
RESULTADOS
  · Relatorios
  · Descadastros
CONTA
  · Configuracoes
```

(Labels exatos: Dashboard, Contatos, Listas, Segmentos, Campanhas, Automacoes, Templates, Dominio de Envio, Relatorios, Descadastros, Configuracoes.)

### Topbar (compartilhada, com variacoes por ambiente)

Altura `h-16`, `bg-surface/80` + `backdrop-blur(12px)` + `border-b border-border`, sticky no topo. Da esquerda para a direita:

1. **Toggle da sidebar** (icone `menu`) — colapsa/expande.
2. **Contexto do ambiente:**
   - Master: pill **"Master Fluxo"** (ciano) + nome da empresa atual quando ha selecao.
   - Empresa: nome da empresa atual + logo/avatar do tenant.
3. **Troca de empresa (SO Master):** combo/command-palette "Trocar empresa" com busca, ultimas acessadas e indicador de saude por empresa (ponto `--success`/`--warning`/`--danger` + label). Ausente no ambiente Empresa.
4. **Busca global** (`Cmd/Ctrl+K`): input `bg-surface-2/60` + `border-border-strong`, abre command palette (empresas, campanhas, contatos, dominios, acoes).
5. **Botao "Criar campanha"** (primario): `fluxo-gradient`, texto branco semibold, `shadow-fluxo`, hover `scale-1.02`. Microcopy do CTA: **"Nova campanha"** (Empresa) / **"Nova campanha global"** (Master).
6. **Status do dominio:** chip com icone + label, nunca so cor. Estados: `Verificado` (`--success`, icone check-shield), `Pendente` (`--warning`, icone clock), `Reputacao em risco` (`--danger`, icone alert). No Master, mostra o agregado ("3 dominios pendentes").
7. **Alertas (sino):** badge numerico `bg-danger` quando ha pendencias criticas; popover lista os mais recentes. Microcopy: "Atencao necessaria".
8. **Indicacao de plano/limite:** mini barra de uso (`Volume usado`): `Pro · 62% do mes`. Cor da barra escala `--success → --warning → --danger`. Clique leva a Planos e Limites (Master) ou Configuracoes (Empresa).
9. **Usuario logado + menu de perfil:** avatar + nome; menu com Perfil, Preferencias, Trocar ambiente (se o usuario tiver acesso Master), Sair.

Estados de acessibilidade: todo item clicavel tem `focus-visible` ring `--focus-ring` 2px + offset; chips de status com `aria-label` descritivo; combo de troca de empresa navegavel por teclado.

### Fluxo de navegacao (mapa)

```
Login
  └─ usuario SO empresa ───────────────► Ambiente EMPRESA (sua empresa) ─► Dashboard
  └─ usuario Master/multi-empresa ─────► escolha de ambiente
         ├─ Master ──► Dashboard Master ─► Empresas ─► [detalhe] ─► "Entrar como suporte"
         │                                                              └─► Ambiente EMPRESA (impersonando, com banner)
         └─ Empresa X ──► Dashboard (tenant)

Em qualquer ponto:
  Cmd/Ctrl+K (busca global)  →  pula para Empresa / Campanha / Contato / Dominio / Acao
  Topbar "Trocar empresa" (Master)  →  troca de tenant sem voltar ao Dashboard Master
  Menu de perfil "Trocar ambiente"  →  Master ⇄ Empresa
```

### Wireframe ASCII — Shell (sidebar + topbar + conteudo)

**Ambiente MASTER:**

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│ ☰  ⚡ Master Fluxo │ Empresa: Todas ▾   🔍 Buscar (Ctrl+K)   [+ Nova campanha global]│
│                    │                              🌐 3 pendentes  🔔3  Pro 62% ▮ CS▾ │
├──────────────────┬────────────────────────────────────────────────────────────────┤
│ ⚡ MASTER FLUXO   │                                                                  │
│                  │   CONTEUDO DA PAGINA                                             │
│ GERAL            │   (Dashboard Master / Empresas / Dominios / ...)                 │
│ ▸ Visao Geral ◀  │                                                                  │
│                  │   ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐    │
│ EMPRESAS&PESSOAS │   │  KPI card  │ │  KPI card  │ │  KPI card  │ │  KPI card  │    │
│ ▸ Empresas       │   └────────────┘ └────────────┘ └────────────┘ └────────────┘    │
│ ▸ Usuarios       │                                                                  │
│                  │   ┌───────────────────────────┐ ┌──────────────────────────┐     │
│ ENVIO & SAUDE    │   │   Grafico volume/dia      │ │  Acoes que precisam de   │     │
│ ▸ Dominios       │   │                           │ │  atencao                 │     │
│ ▸ Entregabilid.  │   └───────────────────────────┘ └──────────────────────────┘     │
│                  │                                                                  │
│ EXECUCAO         │                                                                  │
│ ▸ Campanhas      │                                                                  │
│ ▸ Automacoes     │                                                                  │
│ ▸ Templates Glob.│                                                                  │
│                  │                                                                  │
│ INTELIGENCIA     │                                                                  │
│ ▸ Relatorios     │                                                                  │
│ ▸ Alertas        │                                                                  │
│                  │                                                                  │
│ GOVERNANCA       │                                                                  │
│ ▸ Planos e Limit.│                                                                  │
│ ▸ Auditoria      │                                                                  │
│ ▸ Configuracoes  │                                                                  │
└──────────────────┴────────────────────────────────────────────────────────────────┘
 acento = ciano (--accent)        barra lateral esq do item ativo = border-accent-500
```

**Ambiente EMPRESA:**

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│ ☰  🏢 Acme Vendas Ltda          🔍 Buscar (Ctrl+K)        [+ Nova campanha]          │
│                                            🌐 Verificado  🔔1  Pro 62% ▮  João ▾     │
├──────────────────┬────────────────────────────────────────────────────────────────┤
│ 🏢 ACME VENDAS    │                                                                  │
│                  │   CONTEUDO DA PAGINA (escopo do tenant)                          │
│ OPERACAO         │                                                                  │
│ ▸ Dashboard   ◀  │                                                                  │
│ ▸ Contatos       │                                                                  │
│ ▸ Listas         │                                                                  │
│ ▸ Segmentos      │                                                                  │
│                  │                                                                  │
│ ENVIO            │                                                                  │
│ ▸ Campanhas      │                                                                  │
│ ▸ Automacoes     │                                                                  │
│ ▸ Templates      │                                                                  │
│ ▸ Dominio Envio  │                                                                  │
│                  │                                                                  │
│ RESULTADOS       │                                                                  │
│ ▸ Relatorios     │                                                                  │
│ ▸ Descadastros   │                                                                  │
│                  │                                                                  │
│ CONTA            │                                                                  │
│ ▸ Configuracoes  │                                                                  │
└──────────────────┴────────────────────────────────────────────────────────────────┘
 acento = azul (--primary)        barra lateral esq do item ativo = border-primary       sem "Trocar empresa"
```

**Variacao mobile (shell):** sidebar vira **drawer off-canvas** (icone `menu` abre overlay `surface-glass` da esquerda, `backdrop-blur(12px)` + scrim `bg-base/70`). Topbar reduz para: `menu` · contexto compacto (pill ciano OU avatar do tenant) · `🔍` · `🔔` · avatar. O CTA "Nova campanha" vira **FAB** flutuante (`fluxo-gradient`, canto inferior direito, `shadow-fluxo-lg`). Chip de status do dominio e plano migram para dentro do drawer (cabecalho). Navegacao por gesto de fechar (swipe/scrim tap).

---

## 7. Dashboard Master (wireframe + UI)

Tela de abertura do ambiente Master. Objetivo: em 5 segundos responder **"a plataforma esta saudavel e onde preciso agir?"**. Layout em 4 faixas: (1) KPIs, (2) graficos macro, (3) blocos inteligentes acionaveis, (4) recomendacoes da IA. Densidade alta, mas hierarquia clara por agrupamento e cor de acento.

### Faixa 1 — KPI cards (8)

Grid responsivo `grid-cols-4` (desktop) / `grid-cols-2` (tablet) / `grid-cols-1` (mobile). Cada card: `bg-surface/60` + `border border-border` + `rounded-2xl` + `shadow-lg`, hover `border-primary/30` + `-translate-y-1`. Estrutura: label (`text-text-secondary text-sm`) · valor grande (`text-text font-display text-3xl`; numeros de destaque podem usar `text-accent-500`) · delta vs periodo anterior (seta + %, verde/vermelho com icone, nunca so cor) · sparkline opcional.

| # | Card | Valor | Acento/Estado |
|---|---|---|---|
| 1 | Empresas ativas | nº | neutro; delta vs mes |
| 2 | Emails enviados no mes | nº grande | `--accent` no numero |
| 3 | Taxa media de entrega | % | `--success` ≥98, `--warning` 95–98, `--danger` <95 (icone) |
| 4 | Taxa media de clique | % | neutro + sparkline |
| 5 | Empresas com alerta | nº | `--warning`/`--danger` + icone alert; "Atencao necessaria" |
| 6 | Dominios pendentes | nº | `--warning` + icone clock; link p/ Dominios |
| 7 | Campanhas bloqueadas | nº | `--danger` + icone lock; link p/ aprovacao |
| 8 | Volume usado da plataforma | % barra | escala `--success→--warning→--danger`; "Base saudavel" / "Reputacao em risco" |

Cards 5–8 sao "cards-acao": clicaveis, levam direto ao filtro correspondente. Cards 3 e 8 carregam o status semantico mais forte.

### Faixa 2 — Graficos macro (6)

Paleta de series = chart sequence da marca (`#0066FF, #00F2FE, #3385FF, #10B981, #A855F7, #F59E0B, #EF4444`). Tooltips `surface-glass`, grid `--border`, eixos `--text-muted`.

1. **Volume por dia** — area/linha (envios/dia, 30d), gradiente `fluxo-gradient` sob a linha.
2. **Performance geral** — barras agrupadas: Entrega / Abertura / Clique / Bounce.
3. **Saude de entregabilidade** — gauge ou stacked: Verificados vs Pendentes vs Em risco (cores de status).
4. **Empresas maior uso** — barra horizontal top 5 (% do limite).
5. **Empresas maior risco** — barra horizontal top 5 (bounce+spam), tons `--warning`/`--danger`.
6. **Plano/Receita** — donut MRR por plano (Starter/Pro/Scale) + delta do mes.

### Faixa 3 — Blocos inteligentes (acionaveis)

Cards de lista, cada linha com icone + label + CTA. Sempre status por icone+label, nunca so cor.

- **Acoes que precisam de atencao** — fila priorizada (dominio quebrou, limite estourado, spam alto). CTA por item: "Resolver". Header chip "Atencao necessaria".
- **Empresas com risco de reputacao** — top empresas por bounce/spam; badge `--danger` "Reputacao em risco"; CTA "Ver empresa".
- **Dominios sem SPF/DKIM/DMARC** — lista dominio + tags faltantes (`SPF`/`DKIM`/`DMARC` em pills `--warning`); CTA "Configurar".
- **Campanhas aguardando aprovacao** — empresa · campanha · volume · enviada em; CTA "Revisar". Badge contagem.
- **Recomendacoes da IA** — destaque visual: card com borda `border-accent-500/30` + leve `fluxo-gradient` no header + icone `sparkles`. Itens no tom: **"IA recomenda"** — ex.: "Pausar envios da Acme: bounce subiu 4x em 24h", "Aquecer dominio da BetaCorp antes da campanha de 50k". Cada item: Aplicar / Ignorar.

### Wireframe ASCII — Dashboard Master (desktop)

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│ ☰  ⚡ Master Fluxo │ Todas ▾   🔍 Ctrl+K   [+ Nova campanha global]  🌐3  🔔3  62%▮ ▾│
├──────────────┬────────────────────────────────────────────────────────────────────┤
│ SIDEBAR      │  Visao Geral                                       Periodo: 30d ▾    │
│ (Master)     │                                                                      │
│              │  ┌──────────┐┌──────────┐┌──────────┐┌──────────┐                    │
│              │  │Empresas  ││Emails mes││Entrega   ││Clique    │                    │
│              │  │  ativas  ││ 2,4M  ▲  ││ 98,1% ✔  ││ 3,2%  ▲  │                    │
│              │  │  142  ▲5 ││(ciano)   ││(success) ││~~spark~~ │                    │
│              │  └──────────┘└──────────┘└──────────┘└──────────┘                    │
│              │  ┌──────────┐┌──────────┐┌──────────┐┌──────────┐                    │
│              │  │Empresas  ││Dominios  ││Campanhas ││Volume    │                    │
│              │  │c/ alerta ││pendentes ││bloqueadas││plataforma│                    │
│              │  │  7  ⚠    ││  3  ⏱    ││  2  🔒   ││ 62% ▮▮▮░ │                    │
│              │  └──────────┘└──────────┘└──────────┘└──────────┘                    │
│              │  ┌─────────────────────────────┐┌─────────────────────────────┐      │
│              │  │ Volume por dia (30d)        ││ Performance geral            │      │
│              │  │   ╱╲   ╱╲╱╲                 ││ ▆ ▆ ▃ ▁  Entr/Abre/Clic/Bnc │      │
│              │  │ ╱   ╲╱     ╲___ (gradient)  ││                              │      │
│              │  └─────────────────────────────┘└─────────────────────────────┘      │
│              │  ┌──────────────┐┌──────────────┐┌──────────────────────────┐        │
│              │  │ Saude entreg.││ Maior uso     ││ Maior risco (bounce/spam)│        │
│              │  │ ◔ verif/pend ││ ▇ Acme 92%    ││ ▇ Acme  bounce 9% ⚠      │        │
│              │  │   /em risco  ││ ▇ Beta 78%    ││ ▇ Gama  spam 1,2% ⚠      │        │
│              │  └──────────────┘└──────────────┘└──────────────────────────┘        │
│              │  ┌─────────────────────────────┐┌─────────────────────────────┐      │
│              │  │ ⚠ Acoes que precisam de     ││ ⚠ Empresas c/ risco de      │      │
│              │  │   atencao                   ││   reputacao                  │      │
│              │  │ • Acme: dominio falhou [Resolver] ││ • Acme  9% bounce [Ver] │      │
│              │  │ • Beta: limite estourado  [Resolver]││• Gama spam ↑ [Ver]   │      │
│              │  └─────────────────────────────┘└─────────────────────────────┘      │
│              │  ┌─────────────────────────────┐┌─────────────────────────────┐      │
│              │  │ Dominios sem SPF/DKIM/DMARC  ││ Campanhas aguardando aprov. │      │
│              │  │ • mail.acme.com [SPF][DKIM]  ││ • Beta · Promo · 50k [Revisar]│    │
│              │  │   [Configurar]               ││ • Gama · News · 12k [Revisar]│     │
│              │  └─────────────────────────────┘└─────────────────────────────┘      │
│              │  ┌────────────────────────────────────────────────────────────┐      │
│              │  │ ✨ Recomendacoes da IA            (borda+header ciano/grad) │      │
│              │  │ • IA recomenda: pausar Acme — bounce subiu 4x/24h          │      │
│              │  │                                   [Aplicar] [Ignorar]      │      │
│              │  │ • IA recomenda: aquecer dominio BetaCorp antes de 50k      │      │
│              │  │                                   [Aplicar] [Ignorar]      │      │
│              │  └────────────────────────────────────────────────────────────┘      │
│              │  ┌─────────────┐                                                      │
│              │  │ Plano/Receita (donut MRR por plano) ▲ +8%                  │      │
│              │  └─────────────┘                                                      │
└──────────────┴────────────────────────────────────────────────────────────────────┘
```

### Nota mobile (Dashboard Master)

Faixas empilham em coluna unica. KPIs viram carrossel horizontal de cards (`snap-x`) — primeiros os de risco (5–8). Graficos colapsam em acordeao ("Volume por dia", "Performance", etc.), abrindo um por vez para preservar legibilidade (nunca grafico denso em largura de celular). **Recomendacoes da IA** sobem para logo abaixo dos KPIs (acao tem prioridade no mobile). Blocos inteligentes viram listas full-width com CTA por item em botao `block`. Seletor de periodo vira chip sticky no topo da area de conteudo.

---

## 8. Tela de Empresas (lista + detalhe)

O coracao operacional do Master: onde se monitora, diagnostica e age sobre cada tenant.

### 8.1 Lista de Empresas

**Barra superior:** titulo "Empresas" · contador · **busca** (nome/dominio) · **filtros** (Status: Ativa/Suspensa/Trial; Plano: Starter/Pro/Scale; Risco: Saudavel/Atencao/Critico) · ordenacao · botao primario **"Nova empresa"** (`fluxo-gradient`, `shadow-fluxo`).

**Tabela** (`bg-surface/60`, header sticky `bg-surface-2`, linhas `border-b border-border`, hover `bg-[--hover]`, zebra sutil). Colunas:

| Coluna | Conteudo / Estado |
|---|---|
| Nome | logo + nome + dominio primario (`text-text-secondary`) |
| Status | chip icone+label: Ativa (`--success`), Trial (`--info`), Suspensa (`--danger`) |
| Plano | pill: Starter / Pro / Scale |
| Emails usados/mes | nº + mini barra de progresso |
| Limite mensal | nº (`text-text-secondary`) |
| Saude do dominio | chip: Verificado (`--success` shield-check) / Pendente (`--warning` clock) / Em risco (`--danger` alert) |
| Bounce | % — `--success`<2 / `--warning`2–5 / `--danger`>5 (icone) |
| Spam | % — `--success`<0,1 / `--warning` / `--danger` (icone) |
| Ultimo envio | data relativa ("ha 2h") |
| Acoes | menu `⋮`: Ver detalhe · Entrar como suporte · Editar limites · Suspender |

Linhas em risco recebem `border-l-2 border-danger`. Estado vazio: ilustracao + "Nenhuma empresa ainda" + "Nova empresa". Loading: skeleton shimmer (`#0D2B52→#13294D`).

#### Wireframe ASCII — Lista

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ Empresas · 142            🔍 Buscar empresa/dominio   Status▾ Plano▾ Risco▾  [+ Nova empresa]│
├──────────────────────────────────────────────────────────────────────────────────┤
│ NOME            STATUS   PLANO  USADOS/MES   LIMITE   DOMINIO     BNC   SPAM  ULT.   ⋮│
│ ─────────────────────────────────────────────────────────────────────────────────── │
│ 🟦 Acme Vendas  ●Ativa   Pro    92k ▮▮▮▮░    100k   ⚠Em risco   9% ⚠  1,2%⚠ ha2h  ⋮│ ◀ border-l danger
│    acme.com                                                                          │
│ 🟦 BetaCorp     ●Ativa   Scale  78k ▮▮▮░░    250k   ✔Verificado 1%   0,0%  ha1h  ⋮│
│    betacorp.io                                                                       │
│ 🟦 Gama Ltda    ●Trial   Start  4k  ▮░░░░     10k   ⏱Pendente   3% ⚠ 0,3%⚠ ha5h  ⋮│
│    gama.com.br                                                                       │
│ 🟦 Delta SA     ⛔Suspensa Pro   0   ░░░░░    100k   ✔Verificado  —     —    ha9d  ⋮│
│    delta.com                                                                         │
│ ───────────────────────────────────────────────────────────────────────────────────│
│                              ◂ 1 2 3 … 12 ▸        50 por pagina ▾                    │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### 8.2 Pagina de detalhe da Empresa

**Cabecalho:** logo + nome + chip de status + plano + chip saude do dominio · acoes a direita: **"Entrar como suporte"** (secundario, icone `life-buoy`), "Editar limites", `⋮` (Suspender/Reativar/Excluir).

**Abas** (`border-b border-border`, aba ativa `border-b-2 border-primary text-fluxo-400`):
**Resumo · Usuarios · Dominios · Limites · Campanhas · Metricas · Auditoria**

- **Resumo:** mini-KPIs do tenant (envios mes, entrega, bounce, spam, limite usado), saude do dominio, alertas ativos, recomendacoes da IA especificas da empresa.
- **Usuarios:** tabela (nome, email, papel, ultimo acesso, status) + "Convidar usuario".
- **Dominios:** lista de dominios com status SPF/DKIM/DMARC (pills `--success`/`--warning`), valores DNS em `ui-monospace` com botao copiar, CTA "Verificar agora".
- **Limites:** plano atual, limite mensal, volume usado (barra), throttle/dia, override de limite (com registro em auditoria), upgrade/downgrade.
- **Campanhas:** tabela de campanhas do tenant (nome, status, volume, entrega, abertura, clique, data) — aprovacao de pendentes aqui.
- **Metricas:** graficos do tenant (volume/dia, performance, evolucao de bounce/spam) — paleta chart sequence.
- **Auditoria:** timeline de eventos (quem fez o que, quando), com filtro por tipo; registros de impersonacao destacados.

#### "Entrar como suporte" (impersonacao)

Fluxo critico de governanca:

1. Clique abre **modal de confirmacao** (`surface-glass`, `border-warning/40`): "Voce vai acessar **Acme Vendas** como suporte. Suas acoes ficam registradas em auditoria." Campo opcional "Motivo". Botoes: **"Entrar como suporte"** (`--warning` solido) / Cancelar.
2. Ao confirmar: registro imediato em **Auditoria** (autor Master, empresa-alvo, motivo, timestamp).
3. Sessao entra no ambiente Empresa com **banner persistente** no topo (acima da topbar): faixa `bg-warning/15` + `border-b border-warning` + icone + texto **"Modo suporte: voce esta dentro de Acme Vendas como ti@fluxodigitaltech.com.br"** + botao **"Sair do modo suporte"** (volta ao Master). Banner nao some ao navegar.

#### Wireframe ASCII — Detalhe

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ ⚠ MODO SUPORTE: voce esta dentro de Acme Vendas        [Sair do modo suporte]      │ ◀ so durante impersonacao
├──────────────────────────────────────────────────────────────────────────────────┤
│ ‹ Empresas /  🟦 Acme Vendas Ltda   ●Ativa   Pro   ⚠ Dominio em risco             │
│                                  [⛑ Entrar como suporte] [Editar limites] [⋮]      │
├──────────────────────────────────────────────────────────────────────────────────┤
│ Resumo │ Usuarios │ Dominios │ Limites │ Campanhas │ Metricas │ Auditoria          │
│ ───────                                                                            │
│ ┌─────────┐┌─────────┐┌─────────┐┌─────────┐┌─────────┐                            │
│ │Envios   ││Entrega  ││Bounce   ││Spam     ││Limite   │                            │
│ │ 92k     ││ 96,2%   ││ 9% ⚠    ││ 1,2% ⚠  ││ 92% ▮▮▮▮│                            │
│ └─────────┘└─────────┘└─────────┘└─────────┘└─────────┘                            │
│ ┌──────────────────────────────┐ ┌──────────────────────────────────┐             │
│ │ Saude do dominio             │ │ ✨ IA recomenda                   │             │
│ │ acme.com  ⚠ Em risco         │ │ • Pausar envios: bounce 4x/24h    │             │
│ │ SPF ✔  DKIM ✔  DMARC ⚠       │ │   [Aplicar] [Ignorar]             │             │
│ │ [Verificar agora]            │ │ • Limpar lista inativa (12k)      │             │
│ └──────────────────────────────┘ └──────────────────────────────────┘             │
│ ┌──────────────────────────────────────────────────────────────────┐              │
│ │ Alertas ativos                                                     │              │
│ │ ⚠ Bounce acima de 5% · ⏱ DMARC pendente · 🔒 1 campanha bloqueada │              │
│ └──────────────────────────────────────────────────────────────────┘              │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### Nota mobile (Empresas)

A **tabela vira cards**: cada empresa e um card `bg-surface/60` `rounded-2xl` com nome+logo no topo, chips de Status e Saude do dominio na linha seguinte, e metricas-chave (Usados/Limite com barra, Bounce, Spam) em grid 2 colunas; `⋮` no canto. Cards em risco com `border-l-2 border-danger`. Filtros viram bottom-sheet (icone `filter`). No **detalhe**, as abas viram scroll horizontal `snap-x` (pills); KPIs em grid 2-col; "Entrar como suporte" no topo do card de acoes. O **banner de modo suporte** ocupa largura total, sticky, e sempre visivel.

---

## 9. Dashboard da Empresa

O Dashboard da Empresa e a "sala de comando" do tenant: ao abrir, o usuario deve sentir que esta dentro de um motor de vendas operando em tempo real, nao em um relatorio estatico. Diferenciacao de ambiente: aqui o selo/cor de topbar e da EMPRESA (cor do tenant + logo), nunca o azul Master Fluxo — o azul Fluxo aparece apenas em elementos de produto (botoes primarios, graficos, foco), nao na identidade da barra.

```
+--------------------------------------------------------------------------------------+
| [LOGO EMPRESA]  Acme Ltda          Buscar...            [IA] [?] [sino 3] [avatar v]  |  <- topbar EMPRESA
+--------------------------------------------------------------------------------------+
|                                                                                      |
|  Bom dia, Cleiton 👋   Sua base esta saudavel.            [ Periodo: 30 dias  v ]    |
|  Motor de vendas ativo - 4 envios nas proximas 48h         [ + Criar campanha ]      |
|                                                                                      |
|  +-----------+ +-----------+ +-----------+ +-----------+ +-----------+ +-----------+  |
|  | Contatos  | | Emails    | | Taxa de   | | Abertura  | | Clique    | | Conversao |  |
|  | ativos    | | enviados  | | entrega   | |           | |           | |           |  |
|  | 18.240    | | 92.310    | | 98,2%  ^  | | 41,7%  ^  | | 6,9%   v  | | 312    ^  |  |
|  | +320 sem  | | +12% mes  | | otimo     | | +3,1pp    | | -0,4pp    | | R$ 48,2k  |  |
|  +-----------+ +-----------+ +-----------+ +-----------+ +-----------+ +-----------+  |
|  +-----------+ +-----------+                                                          |
|  | Leads     | | Descadas- |                                                          |
|  | engajados | | tros      |                                                          |
|  | 4.512     | | 0,21%  ^  |   <- 8 cards no total (grid 6 col desktop)               |
|  | base 24%  | | dentro    |                                                          |
|  +-----------+ +-----------+                                                          |
|                                                                                      |
|  +----------------------------------------+  +------------------------------------+  |
|  | Performance - ultimos 30 dias          |  | FUNIL DE ENVIO                     |  |
|  | [aberturas - cliques - conversoes]     |  |  Enviado    92.310 ##############   |  |
|  |        .-^-.        .-^.               |  |  Entregue   90.650 #############    |  |
|  |   .--/     \--..--/    \-.   area gradi|  |  Aberto     37.800 ######          |  |
|  |  /  primary->accent fill  \            |  |  Clicado     6.370 ##              |  |
|  | '----------------------------------'   |  |  Convertido    312 #               |  |
|  | leg: o aberturas o cliques o conversao |  |  IA: maior queda em Aberto->Clicado|  |
|  +----------------------------------------+  +------------------------------------+  |
|                                                                                      |
|  +----------------------+  +----------------------+  +----------------------------+  |
|  | Crescimento da base  |  | Melhores campanhas   |  | Segmentos mais engajados   |  |
|  | [linha 90d ascend.]  |  | 1 Black Nov  48,2% ^ |  | Clientes VIP      62% ###  |  |
|  |    _/`\_/`\__/`       |  | 2 Reativa.   39,1%   |  | Trial 14d         54% ###  |  |
|  | +1.840 contatos liq. |  | 3 Boas-vind. 37,7%   |  | Newsletter        38% ##   |  |
|  +----------------------+  +----------------------+  +----------------------------+  |
|                                                                                      |
|  +---------------------------------------------+  +-------------------------------+  |
|  | IA RECOMENDA - Sugestoes para melhorar      |  | Proximos envios agendados     |  |
|  | * Reenvie "Black Nov" p/ nao-abridores      |  | hoje 18:00 Newsletter #48     |  |
|  |   +estimado +1.200 aberturas    [Aplicar]   |  | amanha 09:00 Promo Junho      |  |
|  | * 2.310 contatos sem atividade 90d          |  | qui 14:00 Reativacao trial    |  |
|  |   -> Base com baixa atividade   [Ver]       |  | sex 10:00 Pos-venda lote 3    |  |
|  +---------------------------------------------+  | [ Ver agenda completa ]       |  |
|                                                  +-------------------------------+  |
|  +---------------------------------------------------------------------------------+ |
|  | Base com baixa atividade  -  Atencao necessaria                                 | |
|  | 2.310 contatos (12,6%) sem abrir nos ultimos 90d. Risco de reputacao.           | |
|  | [ Criar campanha de reativacao ]   [ Excluir inativos ]                          | |
|  +---------------------------------------------------------------------------------+ |
+--------------------------------------------------------------------------------------+
```

### Notas de UI

**Header de boas-vindas.** Saudacao com nome (titulo Poppins, `text-text`), subtitulo de estado do motor em `text-text-secondary`. O microcopy de estado e dinamico e usa status semantico: "Sua base esta saudavel" (success), "Atencao necessaria" (warning), "Reputacao em risco" (danger) — sempre com icone, nunca so cor. Seletor de periodo: input estilo `bg-[#0D2B52]/60 border-[#2B3A5C] rounded-lg`. Botao "Criar campanha": botao primario (gradient `--primary`->`--accent`, shadow `fluxo`, hover scale 1.02).

**Cards de KPI (8).** Grid de 6 colunas no desktop (xl), cada card no idioma padrao: fundo `--surface` translucido, `border-[#1E2A44]`, `rounded-2xl`, `shadow-lg`; hover `border-primary/30` + `-translate-y-1`. Estrutura: label (`text-text-secondary` 13px) > valor grande (Poppins, `text-text`, 28px, numeros podem usar `text-accent-500` para acento quando for o KPI-heroi) > delta. Delta com seta + cor de tendencia (success para subida boa, danger para queda ruim, warning para limite) SEMPRE com icone e sinal (^ / v), nunca so cor. Conversoes mostra valor absoluto + receita atribuida em `text-text-muted`. Taxa de entrega e Descadastros tem semantica invertida (subir descadastro = ruim).

**Performance 30d.** Grafico de area/linha multi-serie. Series usam a chart sequence: aberturas `#0066FF`, cliques `#00F2FE`, conversoes `#10B981`. Preenchimento de area com gradiente `--primary`->`--accent` a baixa opacidade. Grid lines em `--border`, eixos em `text-muted`. Tooltip em `--surface-2` com `border-strong`. Legenda com bolinhas de cor + label.

**Funil de envio.** Barras horizontais decrescentes (enviado>entregue>aberto>clicado>convertido), cada estagio com a chart sequence frio->quente. Cada barra: label + valor absoluto + percentual relativo ao topo. Rodape com insight de IA destacando o maior gargalo ("IA: maior queda em Aberto->Clicado") em `text-accent-500` com icone IA. Clicar num estagio filtra/segmenta os contatos daquele ponto.

**Crescimento da base / Melhores campanhas / Segmentos.** Tres cards em linha. Crescimento: sparkline/linha 90d com saldo liquido. Melhores campanhas: top 3 ranqueado com taxa-heroi (abertura) e seta de tendencia. Segmentos mais engajados: barra de progresso por segmento (`--primary` fill sobre trilho `--border`), percentual a direita.

**IA Recomenda.** Card de destaque (este SIM pode usar glass moderado: `--surface-glass` + `backdrop-blur(12px)` + border `--primary/30`) — sinaliza inteligencia. Header "IA RECOMENDA" com icone, `text-accent-500`. Lista de sugestoes acionaveis, cada uma com micro-acao (`[Aplicar]` botao primario pequeno, `[Ver]` botao ghost). Tom: "IA recomenda".

**Proximos envios agendados.** Card lista com horario (mono `text-text-secondary`) + nome da campanha + status dot. CTA secundario "Ver agenda completa".

**Base com baixa atividade (faixa de alerta).** Banner largo de largura total, fundo `warning-soft` (rgba do `--warning` a baixa opacidade) + border-left 3px `--warning`, icone de alerta + label "Atencao necessaria" (status com icone+label). Dois CTAs: primario "Criar campanha de reativacao", secundario ghost-danger "Excluir inativos". Se ultrapassar limiar critico, escala para `--danger` + microcopy "Reputacao em risco".

### Variacao mobile

```
+-----------------------------+
| [logo] Acme   [IA][sino][v] |
+-----------------------------+
| Bom dia, Cleiton            |
| Base saudavel  [30d v]      |
| [ + Criar campanha ]        |
+-----------------------------+
| Contatos ativos             |
| 18.240        +320 ^        |
+-----------------------------+
| Emails enviados             |
| 92.310        +12% ^        |
+-----------------------------+
|  (cards empilhados 1 col,   |
|   scroll vertical; KPIs-    |
|   heroi primeiro)           |
+-----------------------------+
| [ Performance 30d        v ]|  <- graficos em accordion
| [ Funil de envio         v ]|     (colapsados, abre 1)
| [ Melhores campanhas     v ]|
+-----------------------------+
| IA RECOMENDA            (i) |
| * Reenvie Black Nov         |
|   [ Aplicar ]               |
+-----------------------------+
| ! Atencao necessaria        |
| 2.310 inativos 90d          |
| [ Criar reativacao ]        |
+-----------------------------+
```

Mobile: KPIs em 1 coluna (2 colunas em sm), ordenados por prioridade (KPIs-heroi primeiro). Graficos viram accordions colapsados para evitar scroll infinito — abre um por vez. Faixa de alerta fica fixa proxima ao topo do conteudo apos os KPIs. Topbar compacta mantem selo da EMPRESA. Botoes de acao viram full-width.

## 10. Tela de Contatos

A tela de Contatos e o "cadastro vivo" da base. KPIs no topo dao a saude da base num relance; abaixo, lista filtravel/buscavel. A pagina do contato e uma ficha 360 com linha do tempo de eventos — o historico de relacionamento, nao so dados estaticos.

```
+--------------------------------------------------------------------------------------+
| [LOGO EMPRESA] Acme Ltda    Buscar...              [IA] [?] [sino] [avatar v]         |
+--------------------------------------------------------------------------------------+
| Contatos                                          [ Importar CSV ]  [ + Criar manual ]|
|                                                                                      |
| +--------+ +--------+ +-------------+ +-------------+ +--------+ +-----------+         |
| | Total  | | Ativos | | Descadastr. | | Invalidos   | | Bounce | | Engajados |         |
| | 22.140 | | 18.240 | | 1.210       | | 640         | | 1.050  | | 4.512     |         |
| +--------+ +--------+ +-------------+ +-------------+ +--------+ +-----------+         |
|                                                                                      |
| [ Buscar nome / email / telefone .......................... ]  [ Filtros (2) v ]     |
|  Filtros ativos: [tag: VIP x] [status: ativo x]                       limpar          |
| +----------------------------------------------------------------------------------+ |
| | [ ] | Contato                | Status    | Tags        | Engajamento | Origem      | |
| |-----|------------------------|-----------|-------------|-------------|-------------| |
| | [ ] | Ana Souza              | * Ativo   | VIP, Trial  | ||||| alto  | Form site   | |
| |     | ana@acme.com          |           |             |             |             | |
| | [ ] | Bruno Lima            | * Ativo   | Newsletter  | |||   medio | Importacao  | |
| |     | bruno@acme.com        |           |             |             |             | |
| | [ ] | Carla Reis            | ! Bounce  | -           | |     baixo | API         | |
| |     | carla@acme.com        |           |             |             |             | |
| | [ ] | Diego M.  (descadastr)| x Descad. | -           | -           | Landing     | |
| +----------------------------------------------------------------------------------+ |
|  [x] 3 selecionados: [ Add tag ] [ Mover p/ lista ] [ Exportar ] [ Excluir ]         |
|                                              < 1 2 3 ... 412 >   20/pag v             |
+--------------------------------------------------------------------------------------+
```

```
+--------------------------------------------------------------------------------------+
| < Voltar   Ana Souza                                        [ Editar ] [ acoes v ]   |
+--------------------------------------------------------------------------------------+
| +-------------------------------+  +-----------------------------------------------+  |
| | (AS)  Ana Souza               |  | LINHA DO TEMPO                                |  |
| | ana@acme.com   * Ativo        |  | hoje 14:02  Abriu "Black Nov"        [aberto] |  |
| | +55 11 9....  engaj.||||| alto|  | hoje 14:00  Recebeu "Black Nov"   [entregue] |  |
| |                               |  | ontem       Clicou link /promo       [clique]|  |
| | Origem    Form site           |  | 12/06       Entrou na lista VIP    [sistema] |  |
| | Base legal Consentimento      |  | 02/06       Consentimento dado    [consent.] |  |
| | Consent.  dado 02/06 (IP log) |  | 28/05       Importada via CSV      [origem]  |  |
| |                               |  | ............................................ |  |
| | Tags  [VIP] [Trial] [+]       |  | (scroll - filtro: todos|aberturas|cliques)   |  |
| | Listas [Clientes][Newsletter] |  +-----------------------------------------------+  |
| +-------------------------------+  +-----------------------------------------------+  |
| | RESUMO DE ENGAJAMENTO         |  | HISTORICO DE CAMPANHAS                         |  |
| | Aberturas 38  Cliques 9       |  | Black Nov   aberto  clicou      24/11         |  |
| | Ult. abertura: hoje           |  | Reativacao  aberto              10/11         |  |
| | Descadastro: nao              |  | Boas-vindas aberto  clicou      02/06         |  |
| +-------------------------------+  +-----------------------------------------------+  |
+--------------------------------------------------------------------------------------+
```

### Notas de UI

**KPIs da base (6).** Cards compactos no idioma padrao, grid 6 colunas. Total (`text-text`), Ativos (success accent no numero), Descadastrados/Invalidos/Bounce com semantica de atencao (numero neutro, mas com icone de status quando relevante), Engajados (`text-accent-500`). Clicar num KPI aplica o filtro correspondente na lista abaixo (ex.: clicar "Bounce" filtra status=bounce).

**Acoes e filtros.** "Importar CSV" = botao secundario (ghost com border `--border-strong`); "Criar manual" = botao primario. Busca: input largo com icone de lupa, placeholder "nome / email / telefone". "Filtros" abre painel/drawer lateral com facetas: tag, lista, status, origem, engajamento (faixas alto/medio/baixo). Chips de filtros ativos abaixo da busca, cada um removivel (x), com "limpar" geral. Estado de contador no botao Filtros "(2)".

**Tabela/lista.** Linhas com `border-b border-[#1E2A44]`, hover `--hover`. Coluna checkbox para selecao em massa. Status sempre icone+label+cor: Ativo (dot success), Bounce (! warning), Invalido (! danger), Descadastrado (x `text-text-muted`). Engajamento como mini-barra (5 blocos, fill `--primary`) + label alto/medio/baixo. Selecao ativa barra de acoes em massa (Add tag, Mover p/ lista, Exportar, Excluir-danger). Paginacao + seletor itens/pagina. Empty state: ilustracao + "Sua base esta vazia. Importe seus contatos para ligar o motor." + CTA Importar.

**Pagina do contato.** Layout em duas colunas. Coluna esquerda (ficha): avatar com iniciais, nome (Poppins), email, status, barra de engajamento; bloco de dados (Origem, Base legal, Consentimento com data + IP logado para LGPD), Tags (chips editaveis com [+]), Listas (chips). Card "Resumo de engajamento" com contadores. Coluna direita: LINHA DO TEMPO de eventos (o destaque) + Historico de campanhas.

**Linha do tempo.** Lista vertical cronologica (mais recente no topo), cada evento com timestamp (mono `text-text-secondary`), descricao e badge de tipo: [aberto] info, [entregue] success-soft, [clique] accent, [sistema]/[origem] muted, [consent.] success. Conector vertical sutil em `--border` ligando os pontos. Filtro de tipo no rodape (todos | aberturas | cliques | sistema). Consentimento e descadastro aparecem como eventos auditaveis (LGPD). Microcopy de timeline factual e datado.

### Variacao mobile

```
+-----------------------------+
| [logo] Contatos    [+] [v]  |
+-----------------------------+
| [Total 22.1k][Ativos 18.2k] |  <- KPIs scroll horizontal
| [Descad 1.2k][Bounce 1.0k]> |     (snap, chips clicaveis)
+-----------------------------+
| [ Buscar............ ] [Fil]|
| [tag:VIP x][status:ativo x] |
+-----------------------------+
| Ana Souza         * Ativo   |
| ana@acme.com   ||||| alto   |
| VIP, Trial                  |
|-----------------------------|
| Bruno Lima        * Ativo   |
| bruno@acme.com ||| medio    |
|-----------------------------|
| Carla Reis        ! Bounce  |
+-----------------------------+
| < 1 2 3 ... 412 >           |
+-----------------------------+

CONTATO (mobile) = abas:
+-----------------------------+
| < Ana Souza      [acoes v]  |
| ana@acme.com  * Ativo       |
| engaj ||||| alto            |
+-----------------------------+
| [Dados][Timeline][Camp.]    |  <- tabs
+-----------------------------+
| (conteudo da aba ativa)     |
+-----------------------------+
```

Mobile: lista vira cards empilhados (contato = card com nome, status, email, engajamento, tags). KPIs em scroll horizontal com snap, clicaveis como chips de filtro. Filtros abrem em bottom-sheet. Pagina do contato usa tabs (Dados / Timeline / Campanhas) em vez de duas colunas. Acoes em massa aparecem em barra fixa no rodape quando ha selecao.

## 11. Tela de Campanhas

Campanhas e uma vitrine visual, nao uma planilha: cada campanha e um card com preview de status e metricas rapidas, para o usuario "sentir" o pulso dos envios. A diferenca de ambiente se mantem (topbar EMPRESA). Status sao um sistema visual consistente reutilizado em todo o produto.

```
+--------------------------------------------------------------------------------------+
| [LOGO EMPRESA] Acme Ltda   Buscar...               [IA] [?] [sino] [avatar v]        |
+--------------------------------------------------------------------------------------+
| Campanhas                                                        [ + Criar campanha ]|
|                                                                                      |
| [Todas][Rascunho][Agendada][Enviando][Enviada][Pausada][Bloqueada]   [ Data: 30d v ] |
|                                                                                      |
| +----------------------------------+  +----------------------------------+           |
| | Black Friday Novembro            |  | Reativacao Trial 14d             |           |
| | Assunto: "So hoje: 40% OFF..."   |  | Assunto: "Sentimos sua falta..." |           |
| | Segmento: Clientes VIP           |  | Segmento: Trial expirado         |           |
| | 24/11/2025 14:00                 |  | 22/11/2025 09:00                 |           |
| | [* Enviada]                      |  | [>> Enviando  62%]               |           |
| | --------------------------------  |  | --------------------------------  |           |
| | Env 12.480  Entr 98,1%           |  | Env 7.740   Entr 97,8%           |           |
| | Abert 48,2% Clk 9,1% Conv 132    |  | Abert  --   Clk  --  Conv  --    |           |
| | [ Ver relatorio ]        [...]   |  | [ Acompanhar ]           [...]   |           |
| +----------------------------------+  +----------------------------------+           |
| +----------------------------------+  +----------------------------------+           |
| | Newsletter Junho #48 (rascunho)  |  | Promo Junho (bloqueada)          |           |
| | Assunto: (sem assunto)           |  | Assunto: "Ofertas de junho..."   |           |
| | Segmento: --                     |  | Segmento: Base geral             |           |
| | editado ha 2h                    |  | agendada 25/06 10:00             |           |
| | [o Rascunho]                     |  | [! Bloqueada - dominio]          |           |
| | --------------------------------  |  | --------------------------------  |           |
| | Sem metricas ainda               |  | Envio impedido: verifique DKIM   |           |
| | [ Continuar editando ]   [...]   |  | [ Resolver dominio ]     [...]   |           |
| +----------------------------------+  +----------------------------------+           |
|                                                            < 1 2 3 >  grid|lista     |
+--------------------------------------------------------------------------------------+
```

```
ANATOMIA DO CARD DE CAMPANHA
+------------------------------------------+
| Nome da campanha            [status pill]|  <- titulo Poppins + pill de status (icone+label)
| Assunto: "linha de assunto..."           |  <- text-secondary, truncado
| Segmento: Clientes VIP                   |  <- text-muted
| 24/11/2025 14:00                         |  <- data (envio/agendamento/edicao) mono
|------------------------------------------|  <- divisor border
| Env 12.480   Entr 98,1%                  |  } metricas rapidas em grid 2x3
| Abert 48,2%  Clk 9,1%   Conv 132         |  } numeros Poppins, labels muted
|------------------------------------------|
| [ Ver relatorio ]                  [...] |  <- CTA primario contextual + menu acoes
+------------------------------------------+
```

### Notas de UI

**Sistema de status (pills).** Reutilizado em todo o produto. Cada status = icone + label + cor, nunca so cor:
- Rascunho: dot/circulo vazio, `text-text-muted`, fundo neutro.
- Agendada: icone relogio, `--info`, soft bg.
- Enviando: icone setas/spinner + percentual de progresso, `--primary` (`text-accent-500`), animacao `pulse-soft`.
- Enviada: check, `--success`, soft bg.
- Pausada: icone pause, `--warning`.
- Bloqueada: icone alerta, `--danger` — sempre acompanha motivo curto ("dominio", "reputacao").

**Filtros de status.** Barra de tabs/chips por status no topo (Todas + um por status), com contador opcional. Filtro de data a direita (input padrao). Toggle grid|lista no rodape: grid e o default visual; lista e tabela densa para quem prefere.

**Card de campanha.** Idioma de card padrao (navy translucido, `border-[#1E2A44]`, `rounded-2xl`, `shadow-lg`, hover `border-primary/30` + lift). Anatomia: nome (Poppins) + pill de status no canto; assunto (`text-text-secondary`, truncado uma linha); segmento (`text-text-muted`); data (mono); divisor; bloco de metricas rapidas em grid (Env, Entr, Abert, Clk, Conv) com numeros em Poppins e labels muted; rodape com CTA primario CONTEXTUAL (varia por status: "Ver relatorio" enviada, "Acompanhar" enviando, "Continuar editando" rascunho, "Resolver dominio" bloqueada) + menu de acoes [...] (Duplicar, Renomear, Arquivar, Excluir, Ver destinatarios). Campanha bloqueada destaca-se com border-left `--danger` e troca metricas pelo motivo do bloqueio.

**Estado enviando.** Card mostra barra de progresso fina (`--primary`->`--accent`) + percentual, metricas em "--" ate consolidar, animacao `pulse-soft` no pill. Microcopy "Enviando 62%".

**Botao criar campanha.** Botao primario no topo direito. Empty state: card grande tracejado "Nenhuma campanha ainda. Crie a primeira e ligue o motor." + CTA.

### Variacao mobile

```
+-----------------------------+
| [logo] Campanhas    [+] [v] |
+-----------------------------+
| [Todas][Rasc][Agend][Env..]>|  <- chips scroll horizontal
| [ Data: 30d v ]             |
+-----------------------------+
| Black Friday Novembro       |
| "So hoje: 40% OFF..."       |
| VIP - 24/11 14:00           |
| [* Enviada]                 |
| Env 12.480  Entr 98,1%      |
| Abert 48,2% Clk 9,1%        |
| [ Ver relatorio ]      [...]|
+-----------------------------+
| Reativacao Trial 14d        |
| [>> Enviando 62%]           |
| ===progresso=========       |
| [ Acompanhar ]         [...]|
+-----------------------------+
| Promo Junho                 |
| [! Bloqueada - dominio]     |
| [ Resolver dominio ]   [...]|
+-----------------------------+
```

Mobile: cards full-width empilhados (1 coluna). Filtros de status viram chips em scroll horizontal com snap. Metricas rapidas em grid 2 colunas dentro do card. CTA contextual full-width; menu [...] permanece no canto. Toggle grid|lista some (so cards no mobile).

## 12. Tela de Dominio de Envio

Esta tela transmite seguranca tecnica e controle — o usuario precisa confiar que seus emails vao chegar. O cabecalho com progresso transforma uma tarefa intimidante (DNS) em um checklist guiado. Tom: tecnico mas tranquilizador.

```
+--------------------------------------------------------------------------------------+
| [LOGO EMPRESA] Acme Ltda   Buscar...               [IA] [?] [sino] [avatar v]        |
+--------------------------------------------------------------------------------------+
| Dominio de envio   >  mail.acme.com.br                        [ Verificar novamente ]|
|                                                                                      |
| +----------------------------------------------------------------------------------+ |
| | Seu dominio esta 80% pronto para enviar com seguranca                            | |
| | [==================================------]  80%                                  | |
| | Status geral: ! Atencao necessaria - 1 item pendente   Ult. verif: hoje 13:40    | |
| +----------------------------------------------------------------------------------+ |
|                                                                                      |
| +----------------------------------------------------------------------------------+ |
| | * SPF              Verificado                                          [ v ]      | |
| |   Autoriza nossos servidores a enviar em seu nome.                               | |
| |   TXT   @                                                                        | |
| |   v=spf1 include:_spf.fluxo.com.br ~all                    [ copiar ]  [ ajuda ] | |
| +----------------------------------------------------------------------------------+ |
| | * DKIM             Verificado                                          [ v ]      | |
| |   Assina seus emails para provar autenticidade.                                  | |
| |   CNAME  fluxo._domainkey                                                        | |
| |   fluxo._domainkey.mail.acme.com.br.dkim.fluxo.com.br      [ copiar ]  [ ajuda ] | |
| +----------------------------------------------------------------------------------+ |
| | ! DMARC            Pendente                                            [ ^ ]      | |
| |   Define o que fazer com emails nao autenticados. (recomendado)                  | |
| |   TXT   _dmarc                                                                   | |
| |   v=DMARC1; p=quarantine; rua=mailto:dmarc@acme.com.br     [ copiar ]  [ ajuda ] | |
| |   > Ainda nao detectamos este registro. Adicione no seu provedor de DNS.         | |
| +----------------------------------------------------------------------------------+ |
| | * Return-Path      Verificado            CNAME  bounce   ...    [copiar] [v]      | |
| | * Tracking domain  Verificado            CNAME  track    ...    [copiar] [v]      | |
| +----------------------------------------------------------------------------------+ |
|                                                                                      |
|  IA recomenda: configure o DMARC para proteger sua reputacao e melhorar entrega.     |
+--------------------------------------------------------------------------------------+
```

### Notas de UI

**Cabecalho com progresso.** Bloco de destaque no topo (card glass moderado opcional). Titulo dinamico com percentual: "Seu dominio esta 80% pronto para enviar com seguranca" (Poppins). Barra de progresso: trilho `--border`, preenchimento gradient `--primary`->`--accent`; em 100% vira `--success`. Linha de status geral com icone+label (Atencao necessaria = warning; Tudo certo = success; Falha critica = danger) + timestamp da ultima verificacao (mono `text-text-secondary`). Botao "Verificar novamente" primario no topo direito; ao clicar, mostra estado loading (`pulse-soft`/spinner) e atualiza itens.

**Itens DNS (accordions).** Cada registro e uma linha expansivel no idioma de card. Cabecalho da linha: icone+label de status (Verificado = check success; Pendente = ! warning; Erro = x danger; Verificando = spinner), nome do item (SPF, DKIM, DMARC, Return-Path, Tracking domain), chevron expand. Expandido revela: explicacao curta em linguagem simples (`text-text-secondary`), e o registro em si: TIPO (badge: TXT/CNAME) + NOME do registro + VALOR. 

**Valor DNS.** Exibido em fonte mono (`ui-monospace`) em caixa `--surface-2` com `border`, scroll horizontal se longo, com botao [copiar] (icone, feedback "copiado!" via toast/`fade-in-scale`). Link [ajuda] (ghost, abre doc/drawer com passo a passo por provedor). Itens pendentes mostram nota explicativa em faixa `warning-soft` com border-left `--warning` ("Ainda nao detectamos este registro...").

**Hierarquia de estados.** Itens verificados podem vir colapsados/compactos (linha unica com check); item pendente vem expandido por padrao para guiar a acao. Ordenacao: pendentes/erros primeiro. Rodape com sugestao de IA ("IA recomenda...") em `text-accent-500` com icone.

**Ambiente.** Topbar EMPRESA. O dominio de envio integra com a infra Fluxo (include `_spf.fluxo.com.br`, `dkim.fluxo.com.br`) — reforca "stack propria".

### Variacao mobile

```
+-----------------------------+
| [logo] Dominio       [v]    |
| mail.acme.com.br            |
+-----------------------------+
| 80% pronto p/ enviar        |
| [==============----] 80%    |
| ! Atencao - 1 pendente      |
| ult. verif hoje 13:40       |
| [ Verificar novamente ]     |
+-----------------------------+
| ! DMARC        Pendente  ^  |
| Define o que fazer com...   |
| TXT  _dmarc                 |
| +-------------------------+ |
| |v=DMARC1; p=quarantine;..| |
| +-------------------------+ |
| [ copiar ]      [ ajuda ]   |
| > Ainda nao detectamos...   |
+-----------------------------+
| * SPF          Verificado v |
| * DKIM         Verificado v |
| * Return-Path  Verificado v |
| * Tracking     Verificado v |
+-----------------------------+
```

Mobile: cabecalho de progresso empilhado, botao "Verificar novamente" full-width. Itens DNS empilhados; valor DNS em caixa mono com scroll horizontal interno (nao quebra o registro). [copiar] e [ajuda] lado a lado. Pendentes expandidos primeiro, verificados colapsados. Toast "copiado!" no rodape.

## 13. Tela de Relatorios

Relatorios prova o ROI do motor: cards de topo dao o panorama, e o funil + temporais explicam o "porque". Receita atribuida e o KPI-heroi (justifica o investimento). Tom: dados que viram decisao.

```
+--------------------------------------------------------------------------------------+
| [LOGO EMPRESA] Acme Ltda   Buscar...               [IA] [?] [sino] [avatar v]        |
+--------------------------------------------------------------------------------------+
| Relatorios   [ Campanha: todas v ] [ Periodo: 30d v ]              [ Exportar v ]    |
|                                                                                      |
| +--------+ +--------+ +--------+ +--------+ +--------+ +--------+ +--------+ +-------+ |
| |Enviados| |Entregue| |Abertur.| |Cliques | |Descad. | |Bounces | | Spam   | |Conver.| |
| | 92.310 | | 90.650 | | 37.800 | | 6.370  | | 196    | | 1.660  | | 21     | | 312   | |
| |        | | 98,2%  | | 41,7%  | | 6,9%   | | 0,21%  | | 1,8%   | | 0,02%  | |R$48,2k| |
| +--------+ +--------+ +--------+ +--------+ +--------+ +--------+ +--------+ +-------+ |
|                                                  ^ Receita atribuida = KPI heroi -----+
|                                                                                      |
| +------------------------------------+  +------------------------------------------+ |
| | FUNIL                              |  | DESEMPENHO NO TEMPO                       | |
| | Enviado    92.310 ############### |  |   aberturas / cliques / conversoes        | |
| | Entregue   90.650 ##############  |  |      .-^.       .-^-.                      | |
| | Aberto     37.800 #######         |  |  .--/    \-..--/     \--.   (multi-serie)  | |
| | Clicado     6.370 ##              |  | '-----------------------------------'      | |
| | Convertido    312 #               |  |  [dia][semana][mes]                        | |
| +------------------------------------+  +------------------------------------------+ |
|                                                                                      |
| +------------------------------------+  +------------------------------------------+ |
| | LINKS MAIS CLICADOS                |  | CONTATOS MAIS ENGAJADOS                    | |
| | /promo-black       2.310  36,3%   |  | ana@acme.com      38 abert  9 clk         | |
| | /produto/x         1.180  18,5%   |  | bruno@acme.com    31 abert  7 clk         | |
| | /checkout            940  14,8%   |  | carla@acme.com    27 abert  6 clk         | |
| | /blog/dicas          610   9,6%   |  | [ ver todos ]                             | |
| +------------------------------------+  +------------------------------------------+ |
|                                                                                      |
| +-------------------------+  +---------------------------------------------------+   |
| | DISPOSITIVOS            |  | HORARIOS DE MAIOR ENGAJAMENTO                      |   |
| | Mobile  ####### 62%     |  |        seg ter qua qui sex sab dom                |   |
| | Desktop ####   31%      |  |  06-12  .  .  o  O  o  .  .   (heatmap por hora)   |   |
| | Webmail #       7%      |  |  12-18  o  O  O  O  O  o  .                        |   |
| | (donut chart)           |  |  18-24  O  O  o  o  O  .  .   pico: qui 14h-16h    |   |
| +-------------------------+  +---------------------------------------------------+   |
+--------------------------------------------------------------------------------------+
```

### Notas de UI

**Filtros de topo.** Seletor de campanha (todas ou especifica), seletor de periodo, botao "Exportar" (dropdown: CSV, PDF, XLSX) — botao secundario/ghost com icone download. Filtros recalculam todos os blocos.

**Cards de topo (9).** Grid de 9 cards (`grid-cols-3 xl:grid-cols-9`, 3x3 em telas menores), idioma de card compacto. Cada um: label muted + valor absoluto (Poppins) + taxa/percentual relativo embaixo. Semantica de cor por icone: Spam e Bounces tem icone de atencao quando acima do limiar (warning/danger). Receita atribuida e o KPI-HEROI: destacado com `text-accent-500` no valor, leve glow, posicao final de enfase. Descadastros/Spam/Bounces nunca celebram subida (semantica invertida).

**Funil.** Mesmo componente do dashboard: barras horizontais frio->quente (chart sequence), valor + percentual relativo ao topo, gargalo destacado. Clique segmenta contatos do estagio.

**Desempenho no tempo.** Grafico multi-serie (aberturas `#0066FF`, cliques `#00F2FE`, conversoes `#10B981`), toggle granularidade dia/semana/mes. Tooltip `--surface-2`. Area com gradiente suave.

**Tabelas (links / contatos engajados).** Idioma de tabela densa, hover `--hover`. Links mais clicados: URL (truncada, mono), cliques absolutos, % do total, mini-barra. Contatos mais engajados: email + aberturas + cliques, link "ver todos" leva a Contatos filtrado por engajamento alto.

**Dispositivos.** Donut chart com chart sequence + legenda percentual (Mobile/Desktop/Webmail). Numeros grandes podem usar `text-accent-500`.

**Horarios de maior engajamento.** Heatmap dia-da-semana x faixa-horaria; intensidade mapeada em escala `--primary`->`--accent` (frio) ate `--warning` (quente/pico). Celulas com tamanho de ponto (. o O) + cor; legenda de intensidade. Insight textual do pico ("pico: qui 14h-16h") em `text-accent-500`. Acessibilidade: intensidade nunca so por cor — usa tamanho/simbolo + tooltip com valor.

**Exportar.** Toast de confirmacao apos export ("Relatorio gerado") via `fade-in-scale`.

### Variacao mobile

```
+-----------------------------+
| [logo] Relatorios     [v]   |
| [Camp: todas v][30d v]      |
| [ Exportar v ]              |
+-----------------------------+
| [Enviados 92.3k][Entr 98,2%]|  <- cards 2 col
| [Abert 41,7%][Clk 6,9%]     |
| [Descad 0,21%][Bounce 1,8%] |
| [Spam 0,02%]                |
| +-------------------------+ |
| | RECEITA ATRIBUIDA       | |  <- heroi destacado full-width
| | R$ 48,2k        ^ +12%  | |
| +-------------------------+ |
+-----------------------------+
| [ Funil               v ]   |  <- blocos em accordion
| [ Desempenho no tempo v ]   |
| [ Links mais clicados v ]   |
| [ Contatos engajados  v ]   |
| [ Dispositivos        v ]   |
| [ Horarios pico       v ]   |
+-----------------------------+
```

Mobile: cards de topo em grid 2 colunas; Receita atribuida (heroi) sai do grid e vira card destacado full-width. Blocos pesados (funil, temporal, tabelas, heatmap) viram accordions colapsados, abrindo um por vez. Heatmap com scroll horizontal se necessario. Exportar full-width.

## 14. Tela de Templates (galeria)

Galeria visual de templates: o usuario escolhe pelo olho (preview), nao pelo nome. Organizada por categoria, com acoes rapidas (usar/editar/duplicar). Transmite que a plataforma ja vem com munição pronta para vender.

```
+--------------------------------------------------------------------------------------+
| [LOGO EMPRESA] Acme Ltda   Buscar...               [IA] [?] [sino] [avatar v]        |
+--------------------------------------------------------------------------------------+
| Templates                            [ Buscar template... ]      [ + Criar template ]|
|                                                                                      |
| [Todos][Venda][Lancamento][Comunicado][Reativacao][Aniversario][Pos-venda][Nutri..]> |
|                                                                                      |
| VENDA                                                                  ver todos >   |
| +----------------+ +----------------+ +----------------+ +----------------+           |
| | +------------+ | | +------------+ | | +------------+ | | +------------+ |           |
| | |  PREVIEW   | | | |  PREVIEW   | | | |  PREVIEW   | | | |  PREVIEW   | |           |
| | |  (thumb    | | | |   thumb    | | | |   thumb    | | | |   thumb    | |           |
| | |  render)   | | | |            | | | |            | | | |            | |           |
| | +------------+ | | +------------+ | | +------------+ | | +------------+ |           |
| | Oferta Flash   | | Carrinho aband.| | Upsell premium | | Cupom VIP      |           |
| | [Venda]        | | [Venda]        | | [Venda]        | | [Venda]        |           |
| | edit. 12/06    | | edit. 02/06    | | edit. 28/05    | | edit. 20/05    |           |
| | por Ana S.     | | por Sistema    | | por Bruno L.   | | por Ana S.     |           |
| | [Usar][..][..] | | [Usar][..][..] | | [Usar][..][..] | | [Usar][..][..] |           |
| +----------------+ +----------------+ +----------------+ +----------------+           |
|                                                                                      |
| LANCAMENTO                                                             ver todos >   |
| +----------------+ +----------------+ +----------------+ +----------------+           |
| | (cards de template - mesma anatomia)                                   |           |
| +----------------+ +----------------+ +----------------+ +----------------+           |
|                                                                                      |
| REATIVACAO                                                             ver todos >   |
| +----------------+ +----------------+ ...                                            |
+--------------------------------------------------------------------------------------+

ANATOMIA DO CARD DE TEMPLATE
+--------------------+
| +----------------+ |  <- preview render (aspect 4:5), overlay hover com
| |    PREVIEW     | |     acoes; cantos rounded-xl; placeholder skeleton
| |   (thumb)      | |     shimmer durante load
| +----------------+ |
| Nome do template   |  <- Poppins, text
| [Categoria]        |  <- chip de categoria (cor por categoria)
| editado 12/06      |  <- text-muted
| por Ana S.         |  <- criado/editado por (avatar mini + nome)
| [ Usar ] [edit][dup]| <- Usar = primario; editar/duplicar = ghost icon
+--------------------+
```

### Notas de UI

**Layout por categoria.** Pagina organizada em secoes horizontais por categoria (Venda, Lancamento, Comunicado, Reativacao, Aniversario, Pos-venda, Nutricao, Promocao), cada uma com titulo (Poppins) + link "ver todos >". Dentro de cada secao, grid de cards (4 col desktop, responsivo). Barra de filtros/abas de categoria no topo (chips, scroll horizontal) sincroniza com as secoes. Busca por nome a direita.

**Chip de categoria (cor consistente).** Cada categoria tem cor derivada da paleta para reconhecimento rapido — usando chart sequence/tokens: Venda `--primary`, Lancamento `--accent-strong`, Comunicado `--info`, Reativacao `--warning`, Aniversario `#A855F7` (roxo da chart seq), Pos-venda `--success`, Nutricao `#3385FF`, Promocao `--danger`. Sempre chip com label (cor + texto, nunca so cor).

**Card de template.** Idioma de card padrao com destaque no PREVIEW (render real do email, aspect ~4:5, `rounded-xl`). Durante carregamento: skeleton shimmer (`#0D2B52`->`#13294D`). Hover no card: lift + `border-primary/30`, e overlay sobre o preview com acoes rapidas (Usar/Editar/Duplicar/Visualizar). Abaixo do preview: nome (Poppins), chip de categoria, "editado <data>" (muted), "por <autor>" (avatar mini + nome; "por Sistema" para templates nativos da Fluxo). Rodape: [Usar] primario (leva ao editor/criar campanha com o template), [Editar] e [Duplicar] como icon-buttons ghost. Menu [...] extra: Renomear, Pre-visualizar, Excluir (danger), Definir como favorito.

**Templates nativos x do usuario.** Templates "por Sistema" (nativos Fluxo) ganham selo sutil (badge "Fluxo" `text-accent-500`) — reforca que a plataforma ja entrega municao pronta. Usuario pode duplicar e personalizar.

**Estados.** Empty state por categoria: card tracejado "Nenhum template em <categoria>. Crie o primeiro." Busca sem resultado: ilustracao + "Nenhum template encontrado". Botao "Criar template" primario no topo (abre editor em branco ou a partir de bloco).

### Variacao mobile

```
+-----------------------------+
| [logo] Templates    [+] [v] |
| [ Buscar template... ]      |
+-----------------------------+
| [Todos][Venda][Lanc.][Com.]>|  <- chips categoria scroll horiz
+-----------------------------+
| VENDA              ver todos>|
| +-------------+ +-----------+|
| | +---------+ | | +-------+ ||  <- 2 col (1 col em telas
| | | PREVIEW | | | |PREVIEW| ||     muito estreitas)
| | +---------+ | | +-------+ ||
| | Oferta Flash| | Carrinho  ||
| | [Venda]     | | [Venda]   ||
| | 12/06 Ana S | | 02/06 Sist||
| | [Usar]  [..]| | [Usar][..]||
| +-------------+ +-----------+|
+-----------------------------+
| LANCAMENTO         ver todos>|
| +-------------+ +-----------+|
| ...                         |
+-----------------------------+
```

Mobile: secoes por categoria mantidas verticalmente; dentro de cada uma, grid 2 colunas (ou carrossel horizontal com snap como alternativa para "ver todos" da categoria). Card compacto: preview, nome, chip, data+autor em uma linha, [Usar] + menu [...]. Chips de categoria em scroll horizontal no topo. Busca full-width. Acoes secundarias (editar/duplicar) recolhem no menu [...] para economizar espaco.

---

## 15. Criador de Campanha (wizard em etapas)

O Criador de Campanha e a jornada central do "motor de vendas". O usuario nunca dispara as cegas: a cada etapa o painel lateral de **pre-voo** atualiza um diagnostico ao vivo (entregabilidade, risco da base, prontidao). Disparar e o ato final, e ele so destrava com tudo verde.

**Stepper horizontal (6 etapas) + barra de progresso**

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│  ◀ Campanhas        Nova campanha                            [Salvar rascunho]  [Sair]      │  ← topbar
├──────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                            │
│   (1)─────────(2)─────────(3)─────────(4)─────────(5)─────────(6)                          │
│  ●Objetivo   ●Publico    ◉Conteudo   ○Config.   ○Revisao   ○Enviar                         │
│  ✓ feito     ✓ feito     em edicao                                                         │
│                                                                                            │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  Etapa 3 de 6 · 50% │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

Notas do stepper:
- Container: `--bg-base` (#020617). Topbar com `border-b` em `--border` (#1E2A44).
- Nos do stepper: concluido = circulo preenchido `--primary` com check branco (icone + label "feito", nunca so cor); ativo = anel `--accent` (#00F2FE) com glow suave (animacao `glow`); pendente = circulo `--border-strong` (#2B3A5C) vazio, label em `--text-muted` (#64748B).
- Conector entre nos: linha 2px; trecho concluido em `--primary`, trecho futuro em `--border`.
- Barra de progresso: trilha `--surface-2` (#13294D), preenchimento `fluxo-gradient` (#0066FF -> #00F2FE), texto contador em `--text-secondary`.
- Navegacao por teclado: stepper e `<nav aria-label="Etapas da campanha">`, cada no e botao com `aria-current="step"` no ativo; etapas futuras nao concluidas ficam `disabled` ate liberacao.

---

### Layout geral (conteudo + painel pre-voo)

```
┌───────────────────────────────────────────────┬──────────────────────────────┐
│  AREA DA ETAPA (cresce conforme passo)          │  PAINEL PRE-VOO (sticky)     │
│                                                 │                              │
│   [ conteudo da etapa atual ]                   │  ┌────────────────────────┐  │
│                                                 │  │ ⚙ Diagnostico pre-voo  │  │
│                                                 │  │  Pronto para envio?    │  │
│                                                 │  ├────────────────────────┤  │
│                                                 │  │ ✓ Objetivo definido    │  │
│                                                 │  │ ✓ Publico: 12.480      │  │
│                                                 │  │ ◐ Conteudo em edicao   │  │
│                                                 │  │ ○ Config. pendente     │  │
│                                                 │  │ ○ Revisao pendente     │  │
│                                                 │  ├────────────────────────┤  │
│                                                 │  │ Reputacao da base      │  │
│                                                 │  │ ●●●●○  Base saudavel   │  │
│                                                 │  │ Risco de spam: baixo   │  │
│                                                 │  ├────────────────────────┤  │
│                                                 │  │ 🟢 IA recomenda:       │  │
│                                                 │  │ enviar ter. 09h–11h    │  │
│                                                 │  └────────────────────────┘  │
│  [ ◀ Voltar ]                  [ Continuar ▶ ]  │                              │
└───────────────────────────────────────────────┴──────────────────────────────┘
```

Notas do painel pre-voo:
- Card glass de destaque (uso moderado de glass): `--surface-glass` (rgba(13,43,82,.55) + backdrop-blur(12px)), `border` `--border`, `rounded-2xl`, `shadow-lg`. Sticky no scroll.
- Checklist de prontidao reflete o stepper: feito = `--success` + check; em edicao = `--accent` icone meia-lua `◐`; pendente = `--text-muted` + circulo vazio. Sempre icone + label.
- Medidor de reputacao: 5 pontos; preenchidos em escala de status (verde `--success` = saudavel, ambar `--warning` = atencao, vermelho `--danger` = risco). Label textual obrigatorio ("Base saudavel" / "Atencao necessaria" / "Reputacao em risco").
- Bloco IA: chip com `--primary-soft` de fundo, icone, prefixo "IA recomenda:" em `--accent-strong`. Conteudo da recomendacao em `--text`.
- Master x Empresa: no ambiente Empresa o painel herda a cor/selo do tenant na borda superior do card (faixa 3px na cor do tenant) e exibe o nome do remetente verificado da empresa. No ambiente Master (Fluxo) a faixa usa `--primary` e ha selo "Fluxo · Operacao".

---

### Etapa 1 — Objetivo (cards selecionaveis)

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Qual o objetivo desta campanha?                                           │
│  A IA usa o objetivo para sugerir publico, copy e melhor horario.          │
│                                                                            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │   💰        │ │   🌱        │ │   🔁        │ │   🚀        │          │
│  │  Venda      │ │  Nutricao   │ │ Reativacao  │ │ Lancamento  │          │
│  │  Converter  │ │  Educar     │ │ Reengajar   │ │ Novidade    │          │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐                          │
│  │   📢        │ │   📅        │ │   🤝        │   [ selecionado ✓ ]       │
│  │  Comunicado │ │  Evento     │ │  Pos-venda  │                          │
│  └─────────────┘ └─────────────┘ └─────────────┘                          │
└──────────────────────────────────────────────────────────────────────────┘
```

Notas:
- Grid responsivo de cards (`grid-cols-4` desktop, `grid-cols-2` tablet, `grid-cols-1` mobile). Cada card: `--surface`, `border` `--border`, `rounded-2xl`, icone topo, titulo `display`/Poppins, subtitulo `--text-secondary`.
- Estados: hover = `border` `--primary`/30 + lift `-translate-y-1` + `shadow-fluxo`; selecionado = `border` `--primary` solida + fundo `--primary-soft` + badge check no canto (`--primary`); foco teclado = `--focus-ring` 2px + offset.
- Selecao via radio group (`role="radiogroup"`); somente um objetivo. Microcopy de transicao ao continuar: "Objetivo travado. Vamos escolher quem recebe."

---

### Etapa 2 — Publico (lista/segmento + risco da base)

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Para quem vamos enviar?                                                   │
│                                                                            │
│  Origem do publico                                                         │
│  ( • ) Lista        ( ) Segmento        ( ) Filtro avancado                │
│  ┌──────────────────────────────────────────────────────────────┐         │
│  │ ▢ Clientes ativos 2026          8.940 contatos                 │         │
│  │ ▣ Leads qualificados (IA)       3.540 contatos                 │         │
│  │ ▢ Newsletter geral             18.220 contatos                 │         │
│  └──────────────────────────────────────────────────────────────┘         │
│                                                                            │
│  Higiene automatica                                                        │
│  [✓] Excluir descadastrados      [✓] Excluir bounces (hard/soft)           │
│  [✓] Excluir contatos bloqueados / em supressao                            │
│                                                                            │
│  ┌──────────────────────── Estimativa de alcance ───────────────────────┐ │
│  │  Selecionados   3.540   −  Higiene  −312   =   ALCANCE  3.228         │ │
│  │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░  91% entregaveis           │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                            │
│  ┌──────────────────────── RISCO DA BASE ───────────────────────────────┐ │
│  │  ⚠ Atencao necessaria                                                 │ │
│  │  8% dos contatos sem engajamento ha +180 dias.                        │ │
│  │  IA recomenda: criar subsegmento de reengajamento antes do envio.     │ │
│  │  [ Aplicar recomendacao ]   [ Ignorar e seguir ]                      │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘
```

Notas:
- Origem: segmented control (radio). Lista de listas/segmentos com checkbox; contagem alinhada a direita em `mono` para os numeros.
- Higiene automatica: switches marcados por padrao; texto explica que descadastrados/bounces/supressao saem sempre — reforca confianca e protege reputacao.
- Estimativa de alcance: card `--surface-2` com a conta visivel (Selecionados − Higiene = Alcance). Numero de alcance grande em `--text` (Poppins), percentual entregavel com barra `fluxo-gradient`.
- **Risco da base**: card de status, nunca so cor. Estados:
  - `Base saudavel` — borda/icone `--success`, sem acao obrigatoria.
  - `Atencao necessaria` — borda/icone `--warning`, CTA "Aplicar recomendacao" (primario suave) + "Ignorar e seguir".
  - `Reputacao em risco` — borda/icone `--danger`, ring `--ring-danger`; bloqueia avanco ate confirmar acao ("Reduzir publico" / "Limpar base").
- O painel pre-voo atualiza o medidor de reputacao em tempo real conforme a higiene e o segmento mudam.

---

### Etapa 3 — Conteudo (assunto, remetente, editor, IA, previa, teste)

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Conteudo do email                                                         │
│                                                                            │
│  Remetente   [ Fluxo Vendas <vendas@empresa.com> ▾ ] ✓ dominio verificado  │
│                                                                            │
│  Assunto     [ Sua proposta esta pronta — abra antes de sexta        ] 48  │
│              ✨ IA p/ assunto   ·  forca: ●●●●○  ·  spam-words: 0          │
│  Pre-header  [ Resumo que aparece ao lado do assunto na caixa        ] 64  │
│                                                                            │
│  ┌──────────── Editor visual ─────────────┐  ┌───── Previa ─────┐          │
│  │  [ blocos / arrastar / templates ]     │  │ [Desktop][Mobile] │          │
│  │                                        │  │  ┌─────────────┐  │          │
│  │  (abre o Editor de Email — secao 16)   │  │  │ logo        │  │          │
│  │                                        │  │  │ headline    │  │          │
│  │  [ ✨ Melhorar copy com IA ]           │  │  │ [ CTA ]     │  │          │
│  │  [ Escolher template ]                 │  │  │ rodape/desc │  │          │
│  └────────────────────────────────────────┘  └──────────────────┘          │
│                                                                            │
│  [ Enviar teste para mim ]   [ Enviar teste para... ]                      │
└──────────────────────────────────────────────────────────────────────────┘
```

Notas:
- Remetente: dropdown so com remetentes/dominios verificados; selo `✓ dominio verificado` em `--success`. Se nao verificado, badge `--warning` e link "Verificar dominio".
- Assunto/Pre-header: inputs `--surface`/60 + `border` `--border-strong`, `focus ring --primary`/20, contador de caracteres a direita em `--text-muted`.
- IA p/ assunto (`✨ IA p/ assunto`): chip `--primary-soft`, abre painel com 3 sugestoes; cada sugestao mostra forca prevista e ausencia de spam-words. Medidor de forca = pontos com cor de status + label.
- "Melhorar copy com IA" e "Escolher template": botoes secundarios; o editor em si e a secao 16.
- Previa: toggle Desktop/Mobile (segmented). Render fiel; mobile = moldura estreita.
- Envio de teste: "para mim" (email do usuario logado, `ti@fluxodigitaltech.com.br`) e "para..." (modal com ate N enderecos). Resultado do teste alimenta o checklist da etapa 5 (links ok, descadastro presente).

---

### Etapa 4 — Configuracoes

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Configuracoes de envio                                                    │
│                                                                            │
│  Nome interno      [ Proposta Q3 — base qualificada              ]         │
│  Tags da campanha  [ #vendas ] [ #q3 ] [ + ]                               │
│  Rastreamento      [✓] Aberturas   [✓] Cliques   [ ] UTM automatico        │
│  Limite de envio   ( ) Maximo  ( • ) Escalonado (warm-up)  ( ) Por hora    │
│  Reenvio p/ nao-abertos  [ ] Ativar  →  apos [ 48h ] com novo assunto      │
│  Pagina de descadastro   [ Padrao Fluxo ▾ ]   (obrigatoria por lei)        │
└──────────────────────────────────────────────────────────────────────────┘
```

Notas:
- Inputs e switches no idioma padrao. UTM automatico desligado por padrao (privacidade/controle).
- Reenvio para nao-abertos: revela campos so quando ativado (progressive disclosure).
- Pagina de descadastro: obrigatoria, nunca desativavel — texto "(obrigatoria por lei)" em `--text-muted`; alimenta o item "link descadastro presente" da revisao.

---

### Etapa 5 — Revisao (checklist de pre-voo)

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Revisao final — verificacao de pre-voo                                    │
│                                                                            │
│  ✓  Dominio validado                empresa.com · SPF/DKIM/DMARC ok        │
│  ✓  Link de descadastro presente    rodape detectado                       │
│  ✓  Segmento definido               Leads qualificados (IA)                │
│  ✓  Assunto e pre-header            48 / 64 caracteres                      │
│  ✓  Links verificados               12 links · 0 quebrados                  │
│  ✓  Sem contatos bloqueados         supressao aplicada                      │
│  ⚠  Risco de spam                   1 termo sensivel no assunto: "gratis"   │
│  ✓  Estimativa de entrega           3.228 destinatarios · 91% entregaveis   │
│  🟢 Horario recomendado             ter. 09h–11h (IA)                       │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │  IA recomenda: trocar "gratis" por "sem custo" para proteger entrega. │ │
│  │  [ Corrigir automaticamente ]            [ Manter assim ]             │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                            │
│              [ ◀ Voltar ao conteudo ]        [ Tudo certo, agendar ▶ ]     │
└──────────────────────────────────────────────────────────────────────────┘
```

Notas:
- Cada item do checklist = icone de status + label + detalhe. Verde `--success` (✓), ambar `--warning` (⚠), vermelho `--danger` (✕). Nunca apenas cor.
- Itens `--danger` (ex.: dominio nao validado, sem link de descadastro, contatos bloqueados presentes, alto risco de spam) **bloqueiam** o botao "agendar" — CTA fica `disabled` com tooltip "Resolva os itens criticos para liberar o envio".
- Itens `--warning` permitem seguir mas exibem recomendacao da IA com "Corrigir automaticamente" / "Manter assim".
- Botao "Tudo certo, agendar" so vira gradient `fluxo-gradient` ativo quando nao houver item critico; ate la fica em estado `--surface-2` desabilitado.

---

### Etapa 6 — Agendar / Enviar

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Pronto para envio                                                         │
│                                                                            │
│  ( • ) Enviar agora                                                        │
│  ( ) Agendar       [ 24/06/2026 ]  [ 09:00 ]   fuso: America/Sao_Paulo     │
│  ( ) Otimizar com IA  → envia no melhor horario por contato (ter. 09–11h)  │
│                                                                            │
│  ┌─────────────────────── Resumo do voo ────────────────────────────────┐ │
│  │  Objetivo: Venda   ·   Publico: 3.228   ·   Entregaveis: 91%          │ │
│  │  Remetente: vendas@empresa.com (verificado)                          │ │
│  │  Assunto: "Sua proposta esta pronta — abra antes de sexta"           │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                            │
│                          ╔══════════════════════════╗                      │
│                          ║   ⚡ LIGAR O MOTOR        ║   ← CTA final        │
│                          ╚══════════════════════════╝                      │
└──────────────────────────────────────────────────────────────────────────┘
```

Notas:
- Tres modos: Enviar agora / Agendar (date+time+fuso) / Otimizar com IA (send-time optimization por contato).
- "Resumo do voo": ultimo espelho antes do disparo, dados consolidados.
- CTA final "⚡ Ligar o motor": botao primario grande `fluxo-gradient`, branco semibold, `shadow-fluxo-lg`, hover `scale 1.02`, animacao `glow`. Ao confirmar: estado de loading com `pulse-soft` -> tela de sucesso "Motor ligado. Campanha em disparo." com contador ao vivo de envios.
- Master x Empresa: no Master, modo extra "Enviar em nome de empresa X" com selo do tenant; no ambiente Empresa, o CTA exibe o selo/cor do tenant na borda.

---

### Variacao mobile (wizard)

```
┌───────────────────────────┐
│ ◀  Nova campanha      ⋯    │
│ ●●◉○○○  Etapa 3/6 · 50%   │  ← stepper compacto (dots) + progresso
├───────────────────────────┤
│                           │
│   [ conteudo da etapa ]   │
│                           │
│  ┌─────────────────────┐  │
│  │ ⚙ Pre-voo (toque) ▾ │  │  ← painel pre-voo vira bottom-sheet recolhivel
│  │ ◐ Base saudavel     │  │
│  └─────────────────────┘  │
├───────────────────────────┤
│ [ Voltar ]   [ Continuar ]│  ← barra de acao fixa no rodape
└───────────────────────────┘
```

Notas mobile:
- Stepper vira dots (`●` feito / `◉` ativo / `○` pendente) + label "Etapa X/6" + barra. Cards de objetivo em `grid-cols-1`. Editor abre em tela cheia.
- Painel pre-voo vira **bottom-sheet** recolhivel (resumo sempre visivel: reputacao da base); expande sob toque. Botoes Voltar/Continuar fixos no rodape (`sticky bottom-0`, fundo `--bg-subtle`, `border-t` `--border`).

---

## 16. Editor de Email (3 colunas)

Editor de arrastar-e-soltar baseado em blocos. Tres colunas: **biblioteca de blocos** (esquerda), **canvas de preview** (centro), **propriedades do bloco** (direita). Toolbar superior fixa com acoes de documento e verificacoes de pre-voo.

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ ◀ Voltar   Editor de Email                            [Desktop][Mobile] ↶↷  ⛶            │  TOOLBAR
│            ✨ Sugestao IA   🔗 Verificar links   ✂ Verificar descadastro   [Enviar teste] │
│                                                                       [Salvar template ▾] │
├──────────────┬───────────────────────────────────────────────────┬─────────────────────┤
│  BLOCOS      │   CANVAS (preview do email)                        │  PROPRIEDADES       │
│              │                                                    │  Bloco: Botao        │
│  ▦ Texto     │   ┌──────────────────────────────────────────┐    │ ─────────────────── │
│  🖼 Imagem    │   │  [ logo                    ]              │    │  Texto              │
│  ▭ Botao     │   │                                          │    │  [ Quero a proposta]│
│  ▥ Colunas   │   │  Headline em destaque                    │    │  Link / URL          │
│  — Divisor   │   │  Paragrafo de apoio com a oferta...       │    │  [ https://...     ]│
│  ␣ Espacam.  │   │                                          │    │  Cor de fundo        │
│  ⬚ Rodape    │   │   ╔══════════════════╗                   │    │  [▢ #0066FF ]       │
│  ⌘ Redes     │   │   ║  Quero a proposta ║ ◀ selecionado    │    │  Cor do texto        │
│  🎟 Cupom    │   │   ╚══════════════════╝                   │    │  [▢ #F8FAFC ]       │
│  📦 Produto  │   │                                          │    │  Raio  [ 8px ]      │
│  </> HTML*   │   │  ⬚ rodape · descadastro · endereco        │    │  Alinhamento ◧ ▣ ◨ │
│              │   │                                          │    │  Largura  ▣ auto    │
│  *se permit. │   └──────────────────────────────────────────┘    │ ─────────────────── │
│              │        + arraste um bloco para ca                  │  [ Duplicar ][ 🗑 ] │
└──────────────┴───────────────────────────────────────────────────┴─────────────────────┘
```

**Toolbar (topo, fixa)**
- Esquerda: voltar (volta ao wizard, etapa 3). Centro: toggle **Desktop/Mobile** (segmented), **undo/redo** (`↶ ↷`), **tela cheia** (`⛶`).
- Acoes de pre-voo: `✨ Sugestao IA` (analisa copy/estrutura), `🔗 Verificar links` (varre URLs, marca quebradas), `✂ Verificar descadastro` (confirma presenca do link de descadastro — se ausente, badge `--danger`).
- Direita: `Enviar teste` (secundario) e `Salvar template ▾` (split button: Salvar / Salvar como novo).
- Fundo toolbar `--surface`, `border-b` `--border`. Botoes verificacao mostram resultado inline: `--success` ok, `--warning`/`--danger` com contagem.

**Coluna esquerda — Biblioteca de blocos**
- Largura fixa (~200px), `--bg-subtle`, `border-r` `--border`. Cada bloco = item arrastavel com icone + label; hover `--hover`, cursor grab.
- Blocos: Texto, Imagem, Botao, Colunas, Divisor, Espacamento, Rodape, Redes sociais, Cupom, Produto, **HTML custom** (so aparece se a permissao do tenant/role liberar — caso contrario oculto, com tooltip "Disponivel no plano X" para Master).
- Arrastar para o canvas mostra **drop-zone** (linha tracejada `--accent` + label "Solte aqui"). Teclado: bloco focavel + Enter insere no fim; reordenar com setas.

**Centro — Canvas de preview**
- Fundo `--bg-base`; o email renderiza sobre "papel" claro/escuro conforme o template (preview fiel ao que o destinatario ve). Largura troca com o toggle: Desktop (~600px) / Mobile (~360px, moldura estreita).
- Bloco selecionado: contorno `--primary` 2px + handle de mover; hover de bloco: outline `--primary`/30 + mini-toolbar flutuante (mover ↑↓, duplicar, excluir).
- Slot vazio: placeholder tracejado "+ arraste um bloco para ca". Animacao `fade-in-scale` ao inserir bloco.

**Coluna direita — Propriedades do bloco**
- Largura ~280px, `--surface`, `border-l` `--border`. Titulo "Bloco: <tipo>". Campos contextuais ao tipo selecionado (no exemplo, Botao: texto, URL, cor de fundo, cor do texto, raio, alinhamento, largura).
- Color pickers mostram o token/hex em `mono`; defaults puxam tokens da marca (`#0066FF`, `#F8FAFC`). Inputs no padrao (`--surface`/60, `border` `--border-strong`, focus ring `--primary`/20).
- Rodape da coluna: `[ Duplicar ]` e `[ 🗑 Excluir ]` (excluir em `--danger` com confirmacao). Sem bloco selecionado: estado vazio "Selecione um bloco para editar suas propriedades."

**Estados gerais**
- Salvamento: indicador "Salvo ✓" / "Salvando…" (`pulse-soft`) no canto da toolbar.
- Verificacao com erro: barra fina sob a toolbar em `--danger` — "2 links quebrados · 1 sem destino" com [Ver].
- Master x Empresa: no Editor da Empresa, paleta de cores dos pickers traz primeiro as cores do tenant (selo do tenant). No Master, traz tokens Fluxo + indicacao "tema Fluxo".

**Variacao mobile (editor)**

```
┌───────────────────────────┐
│ ◀  Editor  [Desk][Mob] ↶↷ │
│ ✨ 🔗 ✂  [Teste] [Salvar] │
├───────────────────────────┤
│   CANVAS (preview)         │
│   [ bloco selecionado ]    │
├───────────────────────────┤
│ [ + Blocos ] [ Propried. ] │  ← duas gavetas (bottom-sheets)
└───────────────────────────┘
```

No mobile, Blocos e Propriedades viram bottom-sheets acionados por dois botoes fixos no rodape; o canvas ocupa o centro. Edicao de propriedade abre o sheet correspondente.

---

## 17. Tela de Automacoes (lista + construtor visual)

Duas camadas: a **lista de automacoes** (visao gerencial com metricas por fluxo) e o **construtor visual** (canvas de nos conectados). Modelos prontos aceleram a criacao.

### Lista de automacoes

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│  Automacoes                                              [ + Criar automacao ]             │
│  Mantenha o motor girando sozinho.                                                         │
├──────────────────────────────────────────────────────────────────────────────────────────┤
│  Modelos prontos                                                                           │
│  [ Boas-vindas ] [ Reativacao ] [ Aniversario ] [ Pos-compra ] [ Recuperacao de lead ]     │
│  [ Nutricao ] [ Lembrete ] [ Renovacao ]                                                   │
├──────────────────────────────────────────────────────────────────────────────────────────┤
│  Nome                 Status      Leads no fluxo   Conversao   Ultima execucao   Acoes      │
│ ─────────────────────────────────────────────────────────────────────────────────────────│
│  Boas-vindas          🟢 Ativo         1.240         18,4%      ha 3 min        ▷ ✎ ⋯      │
│  Recuperacao de lead  🟢 Ativo           412         9,1%       ha 12 min       ▷ ✎ ⋯      │
│  Aniversario          ⚪ Inativo          0          —          ha 2 dias        ▷ ✎ ⋯      │
│  Pos-compra           🟢 Ativo           876         24,7%      ha 1 min        ▷ ✎ ⋯      │
│  Renovacao            🟠 Pausado          58          6,2%       ha 1 h          ▷ ✎ ⋯      │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

Notas da lista:
- Cabecalho com titulo Poppins + microcopy "Mantenha o motor girando sozinho." + CTA primario `[ + Criar automacao ]` (`fluxo-gradient`).
- Modelos prontos: linha de chips clicaveis (`--surface-2`, `border` `--border`, hover `--primary`/30). Clicar abre o construtor ja populado com o fluxo do modelo. Os 8 modelos: Boas-vindas, Reativacao, Aniversario, Pos-compra, Recuperacao de lead, Nutricao, Lembrete, Renovacao.
- Tabela: status com icone + label (nunca so cor) — `🟢 Ativo` `--success`, `⚪ Inativo` `--text-muted`, `🟠 Pausado` `--warning`. Conversao destacada em `--accent` quando alta. Numeros em `mono`.
- Acoes por linha: `▷` ativar/pausar, `✎` editar (abre construtor), `⋯` menu (duplicar, renomear, metricas, excluir). Linha hover `--hover`.
- Vazio: estado "Nenhuma automacao ainda. Comece por um modelo." com os chips em destaque.

### Construtor visual de fluxo (canvas de nos)

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ ◀  Boas-vindas   🟢 Ativo            [Testar] [Salvar]   zoom −[100%]+   ⛶                 │  TOOLBAR
├───────────────┬────────────────────────────────────────────────────────┬─────────────────┤
│  NOS          │   CANVAS (fluxo)                                        │  PAINEL DO NO    │
│               │                                                         │  No: Enviar email│
│  ⚡ Gatilho   │            ┌───────────────┐                            │ ──────────────── │
│  ⏱ Espera     │            │ ⚡ GATILHO     │                            │  Template         │
│  ◇ Condicao   │            │ Novo contato  │                            │  [ Boas-vindas ▾]│
│  ✉ Enviar     │            └───────┬───────┘                            │  Assunto          │
│  🏷 Add tag   │                    │                                    │  [ Bem-vindo!   ]│
│  ⊘ Rem. tag   │            ┌───────▼───────┐                            │  Remetente        │
│  🔔 Notificar │            │ ⏱ ESPERA       │                            │  [ vendas@... ▾ ]│
│  ⛔ Finalizar │            │ 1 dia          │                            │  ──────────────  │
│               │            └───────┬───────┘                            │  [ Testar no no ]│
│  arraste p/   │            ┌───────▼───────┐                            │  [ Duplicar ][🗑]│
│  o canvas     │            │ ◇ CONDICAO     │                            │                  │
│               │            │ Abriu email?  │                            │                  │
│               │            └──┬─────────┬──┘                            │                  │
│               │          sim │         │ nao                            │                  │
│               │        ┌─────▼───┐ ┌───▼─────┐                          │                  │
│               │        │✉ ENVIAR │ │🏷 ADD TAG│                         │                  │
│               │        │ Oferta  │ │ "frio"  │                          │                  │
│               │        └────┬────┘ └────┬────┘                          │                  │
│               │             │           │                               │                  │
│               │        ┌────▼───┐  ┌────▼─────┐                         │                  │
│               │        │⛔ FIM   │  │🔔 NOTIFIC│                        │                  │
│               │        └────────┘  │ equipe   │                         │                  │
│               │                    └──────────┘                         │                  │
│               │                                          [+ adicionar no]│                  │
└───────────────┴────────────────────────────────────────────────────────┴─────────────────┘
```

Notas do construtor:
- **Toolbar**: voltar, nome do fluxo + status (icone+label), `[Testar]` (executa simulacao com contato fake), `[Salvar]`, controle de zoom, tela cheia. Fundo `--surface`, `border-b` `--border`.
- **Coluna esquerda — paleta de nos** (~190px, `--bg-subtle`): itens arrastaveis com icone + label. Tipos: **Gatilho** (`⚡`, ponto de entrada — `--primary`), **Espera** (`⏱`), **Condicao** (`◇`, ramifica sim/nao — `--info`), **Enviar email** (`✉`, `--primary`), **Adicionar tag** (`🏷`, `--success`), **Remover tag** (`⊘`, `--text-secondary`), **Notificar equipe** (`🔔`, `--warning`), **Finalizar fluxo** (`⛔`, `--danger`). Cor codifica a familia do no, sempre com icone + label.
- **Canvas**: fundo `--bg-base` com grid de pontos sutil (`--border`). Nos = cards `--surface`, `rounded-2xl`, `border` por familia, `shadow-lg`; cabecalho do card com icone + tipo, corpo com resumo da config. No selecionado: `border` `--primary` 2px + glow. Hover lift `-translate-y-1`.
- **Conectores**: linhas ortogonais 2px `--border-strong` com seta; conectores de Condicao saem rotulados `sim` / `nao` (chip pequeno: `sim` `--success`, `nao` `--text-muted`). Ao arrastar de um node-handle, linha tracejada `--accent` ate soltar no proximo no. Conector invalido (ciclo/sem destino) pisca `--danger`.
- **Gatilho** e unico ponto de entrada (topo). **Finalizar fluxo** encerra o ramo. Nos sem saida valida recebem badge `⚠` ate conectar.
- **Painel do no (direita, ~280px)**: config contextual ao no selecionado (no exemplo, Enviar email: template, assunto, remetente, mais `Testar no no`, `Duplicar`, `Excluir`). Sem selecao: estado vazio "Selecione um no para configura-lo." Excluir em `--danger` com confirmacao.
- **Estados**: salvar mostra "Salvo ✓"/"Salvando…" (`pulse-soft`). Fluxo com erro de validacao (no orfao, gatilho ausente, ciclo) bloqueia "Salvar"/"Ativar" e lista os problemas em barra `--danger` sob a toolbar: "1 no sem conexao · gatilho ausente".
- **Master x Empresa**: no construtor da Empresa, nos de email puxam remetentes/templates do tenant e a borda do canvas herda a cor/selo do tenant. No Master (Fluxo), selo "Fluxo · Operacao" e acesso a nos avancados (ex.: webhook, A/B) quando habilitados.

**Variacao mobile (automacoes)**

```
┌───────────────────────────┐
│ ◀ Automacoes      [ + ]    │
│ [Boas-vindas][Reativacao]▸ │  ← modelos: chips com scroll horizontal
├───────────────────────────┤
│ Boas-vindas   🟢 Ativo     │  ← lista vira cards empilhados
│ 1.240 no fluxo · 18,4%     │
│ ha 3 min          ▷ ✎ ⋯    │
├───────────────────────────┤
│ Pos-compra    🟢 Ativo     │
│ 876 no fluxo · 24,7%       │
│ ha 1 min          ▷ ✎ ⋯    │
└───────────────────────────┘
```

Notas mobile:
- Lista vira cards empilhados (nome + status, metricas em uma linha `mono`, acoes a direita). Modelos prontos = chips com scroll horizontal.
- O construtor visual em telas pequenas abre em modo leitura/zoom-pan (canvas nao e ideal para edicao fina em mobile); edicao recomendada em telas maiores, com aviso "Edite o fluxo em uma tela maior para melhor experiencia". Toque no no abre o painel de config como bottom-sheet.

---

Vou redigir as seções solicitadas seguindo rigorosamente os tokens semânticos e o tom da marca Fluxo.

## 18. Responsividade

### Filosofia
O motor de vendas precisa estar acessível em qualquer tela — do war room (monitor ultrawide) ao gestor checando reputação do dominio no celular. Nada de "versao mobile capada": as acoes criticas (Criar campanha, Ver performance, Ligar motor) seguem sempre alcancaveis. Densidade alta no desktop, foco e toque no mobile.

### Breakpoints (alinhados ao Tailwind padrao)

| Token Tailwind | Faixa | Dispositivo-alvo | Layout-mestre |
|---|---|---|---|
| `(base)` | < 640px | Mobile | 1 coluna, sidebar vira drawer + bottom-bar, FAB |
| `sm:` | >= 640px | Mobile landscape / phablet | 1 coluna larga, cards 2-up onde couber |
| `md:` | >= 768px | Tablet retrato | 2 colunas, sidebar colapsada (so icones) |
| `lg:` | >= 1024px | Notebook / tablet paisagem | Sidebar fixa expansivel, 2-3 colunas |
| `xl:` | >= 1280px | Desktop padrao | Sidebar fixa + 3 colunas + painel lateral de detalhe |
| `2xl:` | >= 1536px | Monitor grande / war room | Grid 4-up, painel IA persistente, max-w-screen-2xl centrado |

> Regra de ouro: o container de conteudo usa `max-w-screen-2xl mx-auto px-4 md:px-6 lg:px-8` para nao "esticar" texto em telas ultrawide.

### Comportamento concreto por componente

**Sidebar -> Drawer/Bottom-bar**

```
DESKTOP (xl)              TABLET (md)            MOBILE (base)
+-----+----------------+  +--+----------------+  +-------------------+
| LOGO|  Conteudo      |  |[]|  Conteudo      |  | [=] Fluxo    [@]  | <- topbar
| --- |                |  |[]|                |  +-------------------+
| Dash|                |  |[]|                |  |                   |
| Camp|                |  |[]|                |  |   Conteudo        |
| Cont|                |  |[]|                |  |   (1 coluna)      |
| Dom |                |  |[]|                |  |                   |
| Auto|                |  |[]|                |  |              (+)  | <- FAB
| --- |                |  +--+----------------+  +-------------------+
| [@] |                |   icones-only, tooltip | [Dash][Camp][+][Cont][Mais] <- bottom-bar
+-----+----------------+                         +-------------------+
sidebar fixa 256px       sidebar 72px (icones)    drawer overlay + bottom nav
```

- **lg/xl/2xl:** sidebar fixa (`lg:flex`), 256px, navy `--surface` (#0D2B52) com border-right `--border` (#1E2A44). Item ativo: `--primary-soft` (rgba(0,102,255,.12)) + barra accent #00F2FE a esquerda.
- **md:** sidebar colapsa para 72px so com icones; label aparece em tooltip no hover. Toggle de expansao persiste em sessao.
- **base/sm:** sidebar some; vira **drawer** que entra pela esquerda (overlay `--surface-glass` rgba(13,43,82,.55) + backdrop-blur(12px)) acionado pelo hamburguer `[=]` na topbar. Em paralelo, **bottom-bar** fixa com 5 alvos: Dashboard, Campanhas, **(+) central elevado**, Contatos, Mais. A bottom-bar usa `fixed bottom-0` com `pb-[env(safe-area-inset-bottom)]`.

**Cards empilham**

- Grid responsivo padrao: `grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 gap-4`.
- KPIs do dashboard: `grid-cols-2 lg:grid-cols-4` (no mobile ficam 2x2, nunca 1x4 verticalizado que esconde metrica abaixo da dobra).
- Mantem o idioma de card (border `--border`, `rounded-2xl`, `shadow-lg`); o hover-lift (`hover:-translate-y-1`) e desativado em telas de toque (`@media (hover: none)`).

**TABELAS viram CARDS** (transformacao no breakpoint)

| Breakpoint | Apresentacao da tabela | Detalhe |
|---|---|---|
| `>= lg` | Tabela completa | Todas as colunas, header sticky, ordenacao, selecao multipla, scroll-x interno se necessario |
| `md` | Tabela reduzida | Esconde colunas secundarias (`hidden md:table-cell` invertido); mantem 3-4 colunas-chave + acao |
| `< md` | **Lista de cards** | Cada linha vira um card: titulo (col primaria) + 2-3 metricas em pares label/valor + chip de status + menu `...` |

```
TABELA (lg+)                                  CARD-LISTA (mobile)
+--------------------------------------+      +------------------------------+
| Campanha    Status   Aberta  Cliques |      | Black Friday 2026            |
|--------------------------------------|      | [v Enviada]      IA recomenda|
| Black Frid. Enviada   42%     8,1%   |      | Aberta 42%   Cliques 8,1%    |
| Boas-vindas Rascunho  --      --     |      |                          [...]|
+--------------------------------------+      +------------------------------+
                                              +------------------------------+
                                              | Boas-vindas                  |
                                              | [o Rascunho]                 |
                                              | Pronto para envio        [...]|
                                              +------------------------------+
```

Implementacao HEEx: renderizar `<.data_table>` em `lg:` e `<.data_card_list>` abaixo, alternados por classes (`hidden lg:block` / `lg:hidden`) ou por um helper que decide o componente. Status sempre icone + label (nunca so cor).

**Botoes principais sempre visiveis — FAB no mobile**

- Acao primaria da tela (ex.: "Criar campanha", "Importar contatos") fica inline no header em `>= md`.
- Em `< md`, ela "desce" para um **FAB** (`fixed bottom-20 right-4`, acima da bottom-bar): circulo 56px, `fluxo-gradient` (#0066FF -> #00F2FE), icone `+` branco, `shadow-fluxo-lg`. Microcopy via tooltip/aria-label: "Criar campanha".
- O FAB nunca cobre conteudo critico: lista tem `pb-28` (padding-bottom) reservado.
- Na bottom-bar, o slot central elevado **(+)** duplica o gatilho de criacao para alcance com o polegar.

**Graficos simplificados**

| Breakpoint | Comportamento do grafico |
|---|---|
| `>= xl` | Versao completa: linha + area, eixos, legenda lateral, tooltip rico, comparativo de periodo |
| `lg/md` | Reduz pontos do eixo X (agrupa por semana), legenda abaixo, remove gridlines secundarias |
| `< md` | **Sparkline / barra unica**: numero grande (text-accent-500 #00F2FE) + tendencia + microsparkline; series multiplas viram seletor de aba; pizza vira lista percentual com barra de progresso |

- Sequencia de cores do chart preservada em qualquer tela: #0066FF, #00F2FE, #3385FF, #10B981, #A855F7, #F59E0B, #EF4444.
- Tooltips no mobile abrem por tap (nao hover) e fecham por tap-fora.

### Diferenca Master x Empresa na responsividade
- **Master (Fluxo):** topbar mobile usa `fluxo-gradient-dark`; selo "MASTER" some em telas estreitas, mantido so o ponto/iniciais no avatar.
- **Empresa:** topbar mobile carrega a faixa de cor da empresa (accent do tenant) + logo do tenant; o seletor de empresa vira item dentro do drawer (nao ocupa a topbar estreita).

---

## 19. Acessibilidade

Checklist acionavel. Cada item e uma condicao verificavel em review/QA.

### Contraste (WCAG AA — razoes ja calculadas sobre o tema escuro)

| Combinacao | Razao | Uso permitido |
|---|---|---|
| `--text` #F8FAFC sobre `--bg-base` #020617 | ~17:1 | Tudo (titulos, corpo, micro) — otimo |
| `--text-secondary` #94A3B8 sobre #020617 | ~7:1 | Corpo e labels (passa AA e AAA p/ texto normal) |
| `--text-muted` #64748B sobre #020617 | ~4.6:1 | So texto >= 16px ou nao essencial (passa AA texto normal, no limite — nao usar em texto critico minusculo) |
| Branco sobre `--primary` #0066FF | ~3.5:1 | So texto **grande/semibold** em botao; para texto normal usar `--primary-active` #0052CC (sobe a razao) |
| `--accent` #00F2FE sobre #020617 | alto p/ acento | **Somente** numeros grandes, icones, barras, bordas-ativas — NUNCA texto corrido pequeno |

Regras duras:
- [ ] **Ciano puro nunca como texto pequeno.** Ciano so em headline numerica, icone, sparkline, borda ativa.
- [ ] Texto em botao primario: se for label normal, garantir `--primary-active` #0052CC de base; o gradient #0066FF->#00F2FE so com label **branco semibold** e tamanho >= 14px bold.
- [ ] Links e estados nunca dependem apenas de cor (ver "status nunca so por cor").

### Texto legivel
- [ ] Tamanho base do corpo >= 16px (`text-base`); minimo absoluto 12px (`text-xs`) so para metadados nao essenciais.
- [ ] Altura de linha corpo `leading-relaxed` (>= 1.5); titulos `leading-tight`.
- [ ] Sem texto sobre imagem/gradient sem camada de contraste (`bg-bg-base/60` atras).
- [ ] Fontes: corpo Inter, display Poppins; fallback `system-ui`. Nunca texto em fonte mono exceto valores DNS/codigo.

### Alvos de toque >= 44px
- [ ] Todo elemento clicavel no mobile tem area minima 44x44px (`min-h-11 min-w-11`), mesmo que o icone seja menor (padding compensa).
- [ ] Itens da bottom-bar: 48px de altura, espacamento entre eles >= 8px.
- [ ] FAB: 56px. Menu `...` de cards: hit-area 44px.
- [ ] Linhas de tabela densa no desktop podem ser < 44px (mouse), mas a versao card mobile respeita 44px.

### Estados visuais claros
- [ ] Todo controle tem estados visiveis: default, **hover** (`--hover` rgba(0,102,255,.08)), **focus** (focus-ring), **active** (`--primary-active`), **disabled** (opacity-50 + `cursor-not-allowed`), **loading** (skeleton shimmer #0D2B52->#13294D ou spinner).
- [ ] Disabled nunca comunicado so por cor — adicionar `aria-disabled` e, quando util, tooltip explicando por que esta desabilitado ("Defina um assunto para liberar o envio").

### Navegacao por teclado
- [ ] **Ordem de foco** segue ordem visual/DOM logica: topbar -> sidebar -> header da pagina -> conteudo -> acoes. Sem armadilhas de foco fora de modais.
- [ ] **Modais/drawers:** foco preso dentro (focus-trap), `Esc` fecha, foco retorna ao gatilho ao fechar.
- [ ] **Skip link** "Pular para o conteudo" como primeiro foco da pagina.
- [ ] Atalhos globais (ver tambem command palette):
  - `Cmd/Ctrl+K` -> command palette
  - `C` -> Criar campanha
  - `G depois D` -> ir para Dashboard; `G depois C` -> Campanhas; `G depois O` -> Contatos
  - `/` -> foco na busca
  - `?` -> abrir mapa de atalhos
  - `Esc` -> fechar overlay/cancelar
- [ ] Atalhos nunca disparam dentro de inputs (exceto `Esc`); exibir overlay de ajuda `?` listando-os.

### Labels em inputs
- [ ] Todo input tem `<label for>` associado (visivel, nao so placeholder). Placeholder e exemplo, nao rotulo.
- [ ] Campos obrigatorios marcados com `*` + `aria-required="true"` + texto "(obrigatorio)" para leitor de tela.
- [ ] Agrupamentos usam `<fieldset>`/`<legend>`. Ajuda contextual via `aria-describedby`.
- [ ] Input usa o idioma da marca: bg #0D2B52/60, border `--border-strong` #2B3A5C, `rounded-lg`, focus `ring-2 ring-fluxo-500/20` (`--focus-ring`).

### Feedback de erro claro
- [ ] Erro de campo: borda `--danger` #EF4444 + icone de alerta + mensagem **especifica abaixo do campo** + `aria-invalid="true"` + `aria-describedby` apontando a mensagem.
- [ ] Mensagem explica **o que** e **como corrigir** ("E-mail invalido. Use o formato nome@empresa.com.").
- [ ] Foco move para o primeiro campo com erro ao submeter.
- [ ] Toasts de sucesso/erro tambem expostos via `aria-live` (`polite` p/ sucesso, `assertive` p/ erro).

### Status nunca so por cor (icone + label + aria)
- [ ] Todo chip de status carrega **icone + texto**, nunca so a bolinha colorida:
  - Sucesso/Enviada: check `--success` #10B981 + "Enviada"
  - Atencao/Risco: triangulo `--warning` #F59E0B + "Atencao necessaria"
  - Erro/Falha: x `--danger` #EF4444 + "Falha no envio"
  - Info/Rascunho: circulo `--info` #3B82F6 ou neutro + "Rascunho"
- [ ] Chips expoem `role="status"` ou `aria-label` redundante quando o texto e abreviado.
- [ ] Graficos: series distinguiveis por mais que cor (rotulo direto, padrao de linha, ou legenda numerada).

### Focus-ring visivel
- [ ] Foco sempre visivel: `focus-visible:ring-2 ring-[--focus-ring]` (rgba(0,102,255,.45)) + `ring-offset-2 ring-offset-bg-base`.
- [ ] Variantes por contexto: `--ring-success`, `--ring-warning`, `--ring-danger` em controles correspondentes.
- [ ] Nunca `outline: none` sem substituto. Foco nao some em fundo escuro (ring sobre #020617 garante visibilidade).

### prefers-reduced-motion
- [ ] Respeitar `@media (prefers-reduced-motion: reduce)`:
  - **aurora** (fundo animado): congela em gradiente estatico `fluxo-gradient-dark`.
  - **float / glow / pulse-soft:** desativadas (`animation: none`).
  - **fade-in / fade-in-scale:** reduzidas a `opacity` instantanea (sem transform) ou duracao <= 0.01ms.
  - Transicoes de hover/lift: mantidas so como mudanca de cor, sem translate/scale.
- [ ] Implementar via util Tailwind: `motion-reduce:transition-none motion-reduce:transform-none motion-reduce:animate-none`.
- [ ] Autoplay de qualquer animacao decorativa parado com motion-reduce; nada pisca > 3x/s (sem risco de gatilho fotossensivel).

---

## 20. Empty states

Padrao visual unico para todos: **icone/ilustracao** (linha, accent #00F2FE sobre `--surface`) dentro de circulo `--primary-soft` -> **titulo curto** (`--text`, Poppins) -> **explicacao objetiva** (`--text-secondary`, 1-2 linhas) -> **CTA primario** (`fluxo-gradient`). Container: card centrado `max-w-md mx-auto`, `py-12 text-center`. Quando a tela permite, **CTA secundario fantasma** (link "Saiba como funciona").

```
+---------------------------------------------------+
|                                                   |
|                    ( o )      <- icone em circulo |
|                                  --primary-soft   |
|        Voce ainda nao criou nenhuma campanha.     |  <- titulo --text
|                                                   |
|     Crie sua primeira campanha e comece a vender  |  <- --text-secondary
|     com o motor ligado.                           |
|                                                   |
|            [  + Criar campanha  ]                 |  <- CTA fluxo-gradient
|              Ver como funciona                    |  <- link secundario
|                                                   |
+---------------------------------------------------+
```

### Catalogo de empty states

| Contexto | Icone | Titulo | Explicacao | CTA primario | Secundario |
|---|---|---|---|---|---|
| **Campanhas** | foguete/raio | "Voce ainda nao criou nenhuma campanha." | "Crie sua primeira campanha e comece a vender com o motor ligado." | `+ Criar campanha` | Ver modelos |
| **Contatos** | pessoas/upload | "Sua base ainda esta vazia." | "Importe seus contatos para comecar a se relacionar com sua base." | `Importar contatos` | Adicionar manualmente |
| **Dominio** | escudo/@ | "Seu dominio ainda nao esta configurado." | "Configure seu dominio para melhorar sua entrega." | `Configurar dominio` | Entenda SPF/DKIM |
| **Automacoes** | engrenagem/fluxo | "Nenhuma automacao rodando." | "Crie sua primeira automacao e deixe a operacao rodando sozinha." | `Criar automacao` | Ver templates |
| **Segmentos** | filtro | "Voce ainda nao criou segmentos." | "Agrupe contatos por comportamento e fale com a pessoa certa." | `Criar segmento` | Como segmentar |
| **Templates** | layout | "Nenhum modelo salvo." | "Salve seus melhores e-mails como modelo e reaproveite em segundos." | `Criar modelo` | Galeria de modelos |
| **Relatorios (sem dados)** | grafico | "Ainda nao ha resultados para mostrar." | "Assim que sua primeira campanha for enviada, a performance aparece aqui." | `Criar campanha` | — |
| **Busca sem resultado** | lupa | "Nada encontrado para \"{termo}\"." | "Revise os termos ou limpe os filtros." | `Limpar filtros` | — |
| **Erro de carregamento** | nuvem-raio | "Nao conseguimos carregar agora." | "Algo falhou do nosso lado. Tente novamente em instantes." | `Tentar de novo` | Falar com suporte |
| **Sem permissao** | cadeado | "Voce nao tem acesso a esta area." | "Peca ao administrador da empresa para liberar seu acesso." | `Voltar ao inicio` | — |

### Diferenciacao por ambiente
- **Empresa:** empty state usa accent do tenant no icone/CTA quando configurado; copy fala da "sua base", "sua entrega".
- **Master (Fluxo):** estados vazios de listas agregadas ("Nenhuma empresa cadastrada ainda.", "Sem alertas de reputacao no momento — base saudavel.") usam icone Fluxo e tom de operacao/controle, nao de onboarding.

### Notas de implementacao
- Empty != Loading != Error: cada um e estado proprio. Loading usa skeleton shimmer; Error usa o card "Erro de carregamento"; Empty usa este catalogo.
- Funcao component `<.empty_state icon= title= description= cta= />` reutilizavel; respeita motion-reduce no fade-in do icone.

---

## 21. Microcopy & tom de voz

### Principios de linguagem
1. **Clara antes de criativa.** A pessoa precisa saber o que fazer. Criatividade vem no enquadramento, nao em esconder a acao.
2. **Tom Fluxo: confianca + motor de vendas.** Falamos como produto de tecnologia que faz o trabalho pesado: "motor ligado", "operacao rodando sozinha", "previsibilidade". Nunca tom de agencia ("nossa equipe criou pra voce").
3. **Profissional, nunca infantil.** Sem emoji nas mensagens de sistema, sem gíria forcada. Direto e seguro.
4. **Explique o termo tecnico.** SPF/DKIM/DMARC, bounce, warm-up, soft/hard bounce: sempre com uma frase de traducao na primeira aparicao ("DKIM: a assinatura que prova que o e-mail e seu.").
5. **Nada de mensagem fria ou erro generico.** Proibido "Erro 500", "Algo deu errado" sozinho, "Operacao invalida". Todo erro diz o que houve e o proximo passo.
6. **Texto curto.** Titulo <= 6 palavras; descricao <= 2 linhas; botao 1-3 palavras (verbo no infinitivo ou imperativo de produto).
7. **Voz ativa, sujeito = a pessoa ou o motor.** "Sua base esta saudavel." / "A IA recomenda enviar as 9h."
8. **Consistencia de rotulo.** O mesmo conceito tem sempre o mesmo nome (ver glossario). Nunca "disparo" num lugar e "envio" em outro.

### Glossario de rotulos / CTAs (fonte da verdade)

| Rotulo / CTA | Onde usa | Sentido |
|---|---|---|
| **Ligar motor** | Ativar campanha/automacao; CTA hero | Por a operacao para rodar |
| **Criar campanha** | Acao primaria global / FAB | Iniciar nova campanha |
| **Ver performance** | Card de campanha, dashboard | Abrir metricas/resultados |
| **Melhorar entrega** | Dominio, reputacao | Acoes de deliverability |
| **Base saudavel** | Indicador de saude (verde) | Lista limpa, bom engajamento |
| **Atencao necessaria** | Indicador de saude (amarelo) | Risco moderado, agir logo |
| **Reputacao em risco** | Alerta de dominio/envio (vermelho) | Deliverability ameacada |
| **Pronto para envio** | Pre-voo de campanha (verde) | Tudo validado, pode disparar |
| **IA recomenda** | Sugestoes contextuais | Recomendacao do motor de IA |
| **Importar contatos** | Contatos vazio / acao | Subir base |
| **Configurar dominio** | Dominio vazio / setup | Setup de DNS/auth |
| **Qualificar leads** | IA / omnichannel | Acao da IA de qualificacao |

Verbos preferidos: Criar, Ligar, Ver, Melhorar, Importar, Configurar, Enviar, Testar, Agendar. Evitar: Disparar (prefira Enviar), Submeter, Processar.

### Mensagens de erro (tom certo)

| Situacao | ERRADO | CERTO (tom Fluxo) |
|---|---|---|
| Falha generica de carregamento | "Algo deu errado." | "Nao conseguimos carregar agora. Tente de novo em instantes — seus dados estao seguros." |
| Campo e-mail invalido | "Campo invalido." | "E-mail invalido. Use o formato nome@empresa.com." |
| Dominio nao verificado | "DNS error." | "Ainda nao confirmamos seu dominio. Verifique os registros SPF e DKIM e clique em Verificar." |
| Envio bloqueado por reputacao | "Bloqueado." | "Reputacao em risco. Pausamos o envio para proteger sua entrega. Veja como recuperar." |
| Limite do plano atingido | "Quota excedida." | "Voce atingiu o limite de envios do seu plano. Faca upgrade para manter o motor ligado." |
| Campanha sem assunto | "Required field." | "Defina um assunto para liberar o envio." |

### Mensagens de sucesso

| Situacao | Texto |
|---|---|
| Campanha agendada | "Campanha agendada. O motor dispara no horario marcado." |
| Campanha enviada | "Motor ligado! Sua campanha esta sendo enviada." |
| Contatos importados | "{n} contatos importados. Sua base cresceu." |
| Dominio verificado | "Dominio confirmado. Sua entrega acabou de ficar mais forte." |
| Automacao ativada | "Automacao no ar. A operacao agora roda sozinha." |

### Mensagens de confirmacao (acoes destrutivas/relevantes)

| Acao | Titulo | Corpo | Confirmar / Cancelar |
|---|---|---|---|
| Enviar agora | "Ligar o motor agora?" | "Sua campanha vai para {n} contatos. Essa acao nao pode ser desfeita." | `Ligar motor` / `Revisar antes` |
| Excluir campanha | "Excluir esta campanha?" | "Os dados de performance serao perdidos. Essa acao e permanente." | `Excluir` (danger) / `Cancelar` |
| Pausar automacao | "Pausar a automacao?" | "Os contatos param de avancar ate voce religar." | `Pausar` / `Manter rodando` |
| Remover contatos | "Remover {n} contatos?" | "Eles deixam de receber suas campanhas. Da pra reimportar depois." | `Remover` (danger) / `Cancelar` |

> Botoes destrutivos usam `--danger` #EF4444 com label explicito (nunca so "OK/Sim"). Confirmacao positiva sempre repete o verbo da acao.

---

## 22. Fluxo de navegacao (mapa)

Dois ambientes, duas arvores. Ponto de entrada comum: **Login**. Apos auth, o roteamento decide Master (equipe Fluxo) ou Empresa (tenant).

### Mapa — Ambiente EMPRESA (tenant)

```
                                  [ Login ]
                                      |
                              (auth + tenant)
                                      |
                          +======================+
                          |  TOPBAR (cor tenant) |
                          |  busca / + / perfil  |
                          +======================+
                                      |
        +---------+---------+---------+---------+---------+---------+
        |         |         |         |         |         |         |
   [Dashboard][Campanhas][Contatos][Dominio][Automacoes][Relatorios][Config]
        |         |         |         |         |         |         |
        |         |         |         |         |         |         +-- Marca/cor
        |         |         |         |         |         |         +-- Usuarios
        |         |         |         |         |         |         +-- Plano/uso
        |         |         |         |         |         |
        |         |         |         |         |         +-- Visao geral
        |         |         |         |         |         +-- Por campanha
        |         |         |         |         |         +-- Engajamento
        |         |         |         |         |
        |         |         |         |         +-- Lista automacoes
        |         |         |         |         +-- Editor de fluxo
        |         |         |         |         +-- Templates
        |         |         |         |
        |         |         |         +-- Status DNS (SPF/DKIM/DMARC)
        |         |         |         +-- Verificar / Melhorar entrega
        |         |         |         +-- Reputacao
        |         |         |
        |         |         +-- Lista / Segmentos
        |         |         +-- Importar contatos
        |         |         +-- Detalhe do contato
        |         |
        |         +-- Lista de campanhas
        |         +-- [Criar campanha] --> Editor --> Pre-voo --> Enviar/Agendar
        |         +-- Detalhe + performance
        |
        +-- KPIs + Indicador de saude (sempre visivel) + IA recomenda
```

**Pontos de entrada / atalhos (Empresa):**
- FAB "+" e bottom-bar central -> **Criar campanha** (atalho `C`).
- Command palette `Cmd/Ctrl+K` -> pula para qualquer tela ou acao.
- Indicador de saude no header -> clique abre **Dominio > Reputacao** ou **Contatos > limpeza** conforme o alerta.
- "IA recomenda" -> deep-link para a acao sugerida (ex.: criar campanha em segmento quente).

### Mapa — Ambiente MASTER (Fluxo)

```
                                  [ Login ]
                                      |
                            (auth + role: Fluxo)
                                      |
                      +==============================+
                      | TOPBAR (fluxo-gradient-dark) |
                      |     selo MASTER / busca      |
                      +==============================+
                                      |
        +-----------+-----------+-----------+-----------+-----------+
        |           |           |           |           |           |
  [Visao geral][Empresas][Reputacao][Faturamento][Equipe][Config global]
        |           |           |           |           |           |
        |           |           |           |           |           +-- Tokens/tema
        |           |           |           |           |           +-- Integracoes
        |           |           |           |           |
        |           |           |           |           +-- Usuarios Fluxo
        |           |           |           |           +-- Permissoes
        |           |           |           |
        |           |           |           +-- Planos
        |           |           |           +-- Uso por empresa
        |           |           |
        |           |           +-- Saude global de envio
        |           |           +-- Alertas (reputacao em risco)
        |           |
        |           +-- Lista de empresas
        |           +-- [Entrar como empresa] --> contexto tenant (impersonate)
        |           +-- Criar empresa --> provisiona tenant
        |
        +-- KPIs agregados (MRR, envios, entregabilidade media)
        +-- Alertas operacionais (empresas em risco)
```

**Pontos de entrada / atalhos (Master):**
- **Entrar como empresa** (impersonate): da lista de Empresas, abre o ambiente tenant com banner persistente "Voce esta em {Empresa} como Master — Sair".
- Alerta "Reputacao em risco" no dashboard Master -> deep-link para a empresa afetada.
- Command palette inclui escopo extra: buscar empresa por nome, ir para Faturamento, alternar tema/tokens.
- Troca Master <-> Empresa sempre visivel no canto da topbar; selo/cor mudam para evitar erro de contexto.

---

## 23. Melhorias de UX (recomendacoes)

1. **Pre-voo de campanha (pre-flight checklist).** Antes de "Ligar motor", uma tela de checagem valida assunto, remetente, dominio verificado, links, peso da imagem, presenca de unsubscribe e tamanho do segmento. Estado verde "Pronto para envio" so libera o botao. *Por que:* previne o erro mais caro (disparo ruim para a base inteira) e reforca a sensacao de motor confiavel, nao disparador as cegas.

2. **Indicador de saude sempre visivel.** Chip persistente no header ("Base saudavel" / "Atencao necessaria" / "Reputacao em risco") com icone + label + cor, clicavel para o detalhe. *Por que:* deliverability e o ativo numero 1 do cliente; manter a saude na frente cria habito de cuidar da base e diferencia de painel generico.

3. **Command palette (`Cmd/Ctrl+K`).** Busca universal de telas, campanhas, contatos e acoes ("criar campanha", "verificar dominio"). *Por que:* poder de usuario avancado, navegacao em 2 teclas, sensacao de produto tecnico premium. Reduz cliques no dia a dia da operacao.

4. **Sugestoes de IA contextuais ("IA recomenda").** Cards de recomendacao na tela certa: melhor horario de envio, segmento quente para reativar, assunto alternativo, limpeza de inativos. Sempre com motivo e acao em 1 clique. *Por que:* materializa o posicionamento "IA que qualifica e age 24/7"; transforma dados em proxima acao, nao so relatorio.

5. **Salvamento automatico no editor.** Editor de e-mail e de fluxo salvam rascunho continuamente com indicador "Salvo as HH:MM" e historico de versoes. *Por que:* elimina medo de perder trabalho, viabiliza edicoes longas, padrao esperado de SaaS premium.

6. **Undo global (desfazer acao recente).** Toast "Campanha excluida — Desfazer" com janela de alguns segundos; aplicar a excluir/arquivar/remover contatos/pausar. *Por que:* reduz ansiedade em acoes destrutivas e o custo de erro, mantendo a interface agil (menos modais de confirmacao para acoes reversiveis).

7. **Teste A/B guiado de assunto.** Wizard que cria 2-3 variantes, define percentual de teste e metrica vencedora (abertura/clique) e envia o vencedor para o restante automaticamente. *Por que:* leva o cliente a vender mais com previsibilidade — argumento central da marca — sem exigir conhecimento tecnico.

8. **Preview multi-cliente + modo claro/escuro do e-mail.** Visualizacao em desktop/mobile e em clientes principais (Gmail, Outlook, Apple Mail) antes do envio, com aviso de elementos quebrados. *Por que:* entrega percebida e real melhoram; evita retrabalho e e-mail quebrado na caixa do lead.

9. **Onboarding orientado por progresso.** Barra de setup ("Motor 60% montado") com passos: verificar dominio, importar contatos, criar 1a campanha, ligar 1a automacao. *Por que:* time-to-value rapido; usa a metafora do motor para guiar sem parecer tutorial infantil.

10. **Agendamento inteligente com timezone do contato.** Opcao "enviar no melhor horario de cada contato" alem de horario fixo. *Por que:* aumenta abertura, reforca a inteligencia do produto e a previsibilidade de resultado.

11. **Estados de carregamento otimistas + skeleton consistente.** Acoes refletem na UI imediatamente (otimista) com rollback em erro; listas usam skeleton shimmer padrao. *Por que:* percepcao de velocidade = percepcao de produto premium e tecnico.

12. **Notificacoes/alertas acionaveis (nao so informativos).** Cada alerta ("Bounce alto na ultima campanha") traz a acao embutida ("Limpar inativos", "Pausar automacao"). *Por que:* fecha o ciclo dado -> decisao -> acao dentro da plataforma, sustentando a posicao de "motor de vendas" e nao quadro de avisos.

---

## 24. Criterios de aceite (para desenvolvimento)

Cada criterio e uma condicao objetiva de aprovacao (PASS/FAIL) verificavel em review de design + QA.

| # | Criterio | Condicao objetiva de aprovacao |
|---|---|---|
| 1 | **Parece plataforma premium da Fluxo** | Tema escuro navy (`--bg-base` #020617) aplicado; tipografia Poppins/Inter; uso correto de `fluxo-gradient` em CTAs/hero e sombras de marca (`shadow-fluxo`). Nenhuma tela usa cinza/branco padrao de framework. |
| 2 | **Nao parece painel generico** | Zero componentes "default" sem marca; KPIs, status e graficos usam a identidade Fluxo (accent #00F2FE em numeros/icones, sequencia de chart definida). Inspecao lado a lado com 3 telas: nenhuma confundivel com template Bootstrap/Material cru. |
| 3 | **Identidade consistente (tokens reais)** | 100% das cores vem dos tokens nomeados (`--primary`, `--accent`, `--surface`, status...). Auditoria de CSS/Tailwind nao encontra hex fora da paleta definida. Mesma cor = mesmo token em todas as telas. |
| 4 | **Simples de usar** | Tarefas-chave (criar campanha, importar contatos, verificar dominio) concluiveis em <= 5 passos cada; toda tela tem 1 acao primaria clara. Teste com usuario novo conclui "criar campanha" sem ajuda. |
| 5 | **Separa Master x Empresa** | Ambientes visivelmente distintos: Master usa `fluxo-gradient-dark` + selo MASTER; Empresa usa cor/selo do tenant na topbar. Impersonate mostra banner persistente. Impossivel confundir contexto. |
| 6 | **Destaca metricas** | Dashboard exibe KPIs acima da dobra com numero grande (accent), tendencia e comparativo; indicador de saude sempre visivel. Metrica principal de cada campanha legivel em < 2s. |
| 7 | **Facilita criar campanha** | CTA "Criar campanha" presente em dashboard, lista e via FAB (mobile) + atalho `C`/command palette. Fluxo guiado ate pre-voo "Pronto para envio". |
| 8 | **Facilita configurar dominio** | Tela de dominio mostra status SPF/DKIM/DMARC com icone+label, registros em mono copiaveis (1 clique), botao "Verificar" e copy explicando cada termo. Empty state leva a "Configurar dominio". |
| 9 | **Facilita analisar resultado** | "Ver performance" a 1 clique do card/lista; relatorio com aberturas/cliques/bounce, comparativo e exportacao. Grafico responsivo (simplifica no mobile). |
| 10 | **Responsivo** | Funciona em base/sm/md/lg/xl/2xl: sidebar vira drawer+bottom-bar, tabelas viram cards < md, FAB no mobile, graficos simplificam. Sem scroll horizontal indevido em nenhuma largura testada (320px+). |
| 11 | **Acessibilidade minima (AA)** | Contrastes conforme tabela (corpo >= 4.5:1, AA); foco visivel em todo controle; status com icone+label+aria; labels em todos os inputs; navegacao por teclado completa; `prefers-reduced-motion` respeitado. Auditoria axe/Lighthouse sem violacoes criticas. |
| 12 | **Componentes reutilizaveis** | UI montada com function components HEEx (`<.card>`, `<.button>`, `<.data_table>`, `<.empty_state>`, `<.status_chip>`, `<.kpi>`...); zero duplicacao de markup de componente entre telas. Tokens como tema Tailwind + CSS variables. |
| 13 | **Aparencia moderna/limpa/tecnologica** | Espaçamento consistente (escala Tailwind), `rounded-2xl` em cards, glassmorphism so em overlays/destaques (moderado), animacoes sutis (fade/lift) com motion-reduce. Sem poluicao visual; hierarquia clara. |
| 14 | **Estados completos por tela** | Toda tela com dados tem 4 estados implementados: loading (skeleton), vazio (empty state do catalogo), erro (card de erro acionavel) e sucesso/conteudo. |
| 15 | **Tom de voz Fluxo** | Microcopy segue glossario ("Ligar motor", "Base saudavel"...); erros explicam causa + proximo passo; nenhum erro generico ("algo deu errado" sozinho) em producao. |

Definicao de pronto (DoD): todos os 15 criterios em PASS, revisao de design aprovada, auditoria de acessibilidade sem violacao critica e inspecao de tokens sem hex fora da paleta.