# Editor de E-mail — Diagnóstico & Roadmap de Melhoria

> Auditoria multi-agente do editor de campanha (stack real: Phoenix LiveView + EditorJS + ProseMirror + CodeMirror 6 + MJML). Legenda de prioridade: **P0** (crítico) · **P1** (importante) · **P2** (polimento). `frontend` = validável no browser após `mix assets.build`; `backend` = exige recompilar/deploy (toca `.heex`/Elixir).

## Diagnóstico (por que parece "muito ruim")

Não é um bug isolado — são **3 problemas estruturais que se somam**:

1. **Fragmentação.** Não existe UM editor: existem **5 caminhos de código** (texto, markdown-simples, markdown-wysiwyg, EditorJS-blocos, MJML) com 4 rótulos ambíguos. O usuário não sabe qual modo escolher nem por que perde funções ao trocar.
2. **Perda de confiança / perda de trabalho.** Sem undo/redo no shell, sem indicador "salvo/salvando", o save real só no submit, e **o editor de código MJML (CodeMirror 6) dessincroniza** quando um bloco ou a IA escrevem no textarea → o usuário vê o resultado no preview mas, ao abrir a aba "Código MJML", vê o MJML antigo e pode sobrescrever sem perceber.
3. **Quebra no mobile + governança tardia.** A toolbar de blocos abre só por *hover* (impossível no celular), e todo o pré-voo de entregabilidade (descadastro, domínio, links) só dispara no clique final "Enviar".

> **O motor de render (`builder.ex`, `builder/mjml.ex`, `liquid_renderer.ex`) é sólido e NÃO deve ser reescrito.** A dor está na camada de UI/orquestração dos editores.

**Pior problema:** dessincronização do CodeMirror 6 (bloco/IA escrevem no textarea, mas a `EditorView` nunca é atualizada; ainda há código morto de CM5 mascarando) → perda de trabalho real e invisível.

## ✅ Já corrigido

> Lote revisado por auditoria adversarial (12 achados levantados → 5 confirmados e tratados, 7 refutados). Sintaxe JS validada com `node --check`. **Falta validar em runtime** (build + deploy) — ver seção "Como validar".

- **Preview "lado a lado" espremendo o e-mail (1 caractere por linha nas colunas).** O `#html-split-preview` agora força a largura real do e-mail (≥640px) e rola na horizontal se o painel for estreito, em vez de refluir e quebrar o MJML multi-coluna. O preview fullscreen (com toggle de dispositivo) não foi afetado. — `assets/js/hooks/campaign-edit-live.js`
- **[P0] Dessincronização do CodeMirror 6.** Inserir bloco pronto e "Ajustar com IA" gravavam no textarea mas não atualizavam a `EditorView` — e a IA ainda chamava `cm.CodeMirror.setValue()` (API do CM5, código morto no CM6). Resultado: ao abrir "Código MJML" via-se o MJML antigo e podia-se sobrescrever em silêncio o trabalho do bloco/IA. Agora o `MjmlEditor` escuta `input`/`change` no textarea e sincroniza a view, com flag anti-recursão (`applyingExternal`) e guarda de igualdade contra `saveUpdates`. Código morto do CM5 removido. — `campaign-editors/mjml/index.js`, `_mjml_editor.html.heex`
- **[P1→feito] Submit acidental do form.** Os 15 botões da barra do editor visual (WYSIWYG) ficavam dentro de `<form id=campaign>` sem `type`, então um clique submetia/recarregava a campanha (o handler do ProseMirror só trata `mousedown`, não impede o `click` nativo). Adicionado `type="button"` neles + barra markdown (4) + barra de blocos (1) + diálogos (incl. os 3 botões de exemplo Liquid que tinham só `@click.stop`, sem prevenir o submit). — `_wysiwyg_editor`, `_markdown_editor`, `_block_editor`, `_wysiwyg_dialogs`
- **[P0] Toque no editor de blocos.** A toolbar abria só no `mouseenter` (impossível no celular). Agora abre também no `pointerup` (ignorando mouse), no editor de blocos e nas colunas de Layout. — `campaign-editors/block/index.js`, `block/blocks/layout/index.js`
- **[P1→feito] Vazamento de memória + ciclo de vida do bloco Layout.** `updateColumns()` (trocar 1-1↔1-2↔…) recriava os editores aninhados sem destruir os antigos → vazava uma instância EditorJS (com todos os listeners) por troca. Agora `drawView()` destrói os editores anteriores antes de recriar; adicionados `removed()` (apagar bloco) e `destroy()` (destruir editor), ambos idempotentes e com try/catch. `api`/`block` atribuídos antes do `drawView()`. — `block/blocks/layout/index.js`
- **[P1→feito] Botão de bloco nascia vazio/"null".** Botão novo agora nasce com rótulo "Clique aqui" e os bindings (`innerHTML`, `value`) são guardados contra `null`. — `block/blocks/button/index.js`

### Conhecido / aceito (baixo impacto, não tratado neste lote)
- Ao "Ajustar com IA" / inserir bloco com o cursor ativo no editor de código, o cursor volta pro início (o doc é reescrito inteiro mesmo). Trigger real é sempre um clique em modal, então o impacto é mínimo.
- O `change` redundante disparado pelos callers (block picker / IA) é inofensivo (a guarda de igualdade no sync faz no-op) e segue o padrão de `phx-change` usado no resto do arquivo — mantido de propósito.

## Ganho rápido recomendado (fazer primeiro)

**`type="button"` em todos os `<button>` das toolbars/dialogs dos editores.** Esforço S, risco ~zero. Hoje esses botões ficam dentro do `<form id=campaign>` e, por padrão, `<button>` é `type=submit`; a única proteção é o `@click.prevent` do Alpine. Se o Alpine demorar a hidratar, clicar em "Negrito" submete e recarrega a campanha. — `_wysiwyg_editor.html.heex`, `_markdown_editor.html.heex`, `_wysiwyg_dialogs.html.heex`

## Roadmap

### P0 — crítico
| Item | O que fazer | Esforço | Camada | Arquivos |
|---|---|---|---|---|
| Sincronizar textarea → CodeMirror 6 | Listener `input` no textarea que faz `view.dispatch` (com guarda anti-loop); remover código morto CM5; bloco/IA passam por esse sync | M | backend | `campaign-editors/mjml/index.js:16-25`, `helpers.js`, `_mjml_editor.html.heex:847-852` |
| Suporte a toque no editor de blocos | Abrir toolbox/handle por clique/tap (não só `mouseenter`); media queries no editor | M | frontend | `campaign-editors/block/index.js:126-134`, `block/blocks/layout/index.js:70-78` |
| Checklist de pré-voo proativo | Barra sempre visível reaproveitando `campaign_has_unsubscribe?/1` + verificação de domínio, mostrando estado ANTES do envio | M | backend | `campaign_edit_live.ex:134-180`, `mailings.ex:1081-1150`, `edit_live.html.heex:117-159` |
| Undo/redo no editor de blocos | `editorjs-undo` + Ctrl+Z/Y + botões na toolbar (hoje deletar bloco é irreversível) | M | frontend | `campaign-editors/block/index.js:14-106`, `package.json` |

### P1 — importante
| Item | O que fazer | Esforço | Camada |
|---|---|---|---|
| `type="button"` nas toolbars/dialogs | Impedir submit acidental do form `#campaign` | S | backend |
| Construtor e `destroy()` do bloco Layout | Atribuir `api`/`block` antes de `drawView()` (evita TypeError); `destroy()` que destrói editores aninhados (memory leak) | S | frontend |
| Enter/Tab dentro das colunas do Layout | Rever `preventDefault` do keydown — hoje escrever em coluna é mutilado | M | frontend |
| `deliverable_check` em Agendar e Cadência | Hoje o gate só cobre envio imediato; agenda "com sucesso" e desagenda em silêncio depois | S | backend |
| Surfacing de erro de render no preview | Exibir banner lendo o header `X-Keila-Invalid` que o builder já injeta | S | backend |
| Indicador "Salvo/Salvando" + toast de erro | Expor estado do auto-save (parcial já existe via `phx-change`) | S | backend |
| Button block: placeholder + inlineToolbar | Não renderizar a string "null"; permitir formatar o rótulo | S | frontend |
| Unificar escolha de editor | Um seletor claro (Rico/Markdown/Blocos/MJML) + helper text; resolver capacidades divergentes do markdown (inserção de variáveis `{{ }}`) | M | backend |
| Lint de MJML no CodeMirror | `@codemirror/lint` + linter leve marcando a linha do erro | L | frontend |
| Autosave de rascunho no servidor | Persistir `json_body`/`mjml_body` periodicamente, não só no submit | M | backend |
| `phx-debounce` no campo Assunto | Hoje cada tecla refaz changeset + recipient_count + rebuild_preview | S | backend |
| IA dentro do LiveView | Trocar `fetch` direto + `alert()` por `handle_event` com feedback inline | M | backend |
| Corrigir `<form>` aninhado no MJML | Mover textarea pro form externo `#campaign` (form aninhado é HTML inválido) | S | backend |

### P2 — polimento
| Item | Esforço | Camada |
|---|---|---|
| Valores de enum no autocomplete MJML (`tags.js`) | M | frontend |
| Preview Desktop/Mobile lado a lado + `@styles` no markdown simples | M | backend |
| Limpezas de código morto e listeners vazando (`markdown-it-keila-block`, `destroy()` do MarkdownEditor) | S | frontend |
| Extrair JS inline e quebrar o parcial MJML de 910 linhas | L | backend |
| Paleta de cor da marca + "remover cor"; confirmação ao deletar | S | frontend |
| i18n de strings hardcoded; estado global de alinhamento | M | backend |
| Refatorar orquestração do LiveView + supervisionar tasks de preview | M | backend |
| Acessibilidade das toolbars (`aria-label`) | S | backend |
| Ligar a lib de snippets (`Keila.Templates.Blocks`) ao editor de blocos + bloco Cupom + "Salvar como template" | L | backend |

## Testes (restrição importante)

- **Não dá pra validar de verdade sem o app de pé.** Esta máquina não tem Elixir, o `node_modules` do front não está instalado, e o app roda no servidor. A auditoria foi 100% leitura de código.
- **Testes unitários fazem sentido** para o builder/render (já robusto): `mjml.ex` (compilação + fallback + `X-Keila-Invalid`), `liquid_renderer`, e funções puras (`campaign_has_unsubscribe?`, `deliverable_check`, `parse_cadence_slots`).
- **Os editores (EditorJS/ProseMirror/CM6) exigem teste de browser** (manual após `mix assets.build` + `mix phx.server`, ou suíte e2e tipo Playwright/Wallaby). Comportamento de toque, dessincronização do CM6 e o fluxo de pré-voo precisam de validação manual antes de dar por resolvidos.

## Como validar localmente / no servidor

```bash
cd assets && npm install            # node_modules não está instalado
cd .. && mix assets.build           # recompila o JS (esbuild)
mix phx.server                      # sobe o app pra testar no browser
# em produção: rebuild da imagem Docker (assets.deploy + release roda no Dockerfile)
```
