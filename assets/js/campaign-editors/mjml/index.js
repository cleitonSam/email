import { defaultKeymap } from "@codemirror/commands"
import { html } from "@codemirror/lang-html"
import { EditorState } from "@codemirror/state"
import { EditorView, keymap } from "@codemirror/view"
import { basicSetup } from "codemirror"

import { indentAndAutocompleteWithTab, saveUpdates } from "./helpers.js"
import tags from "./tags.js"
import theme from "./theme.js"

export default class MjmlEditor {
  constructor(place, source) {
    this.source = source
    this.place = place

    let state = EditorState.create({
      doc: source.value,
      extensions: [
        basicSetup,
        html({ extraTags: tags, selfClosingTags: true }),
        keymap.of([...defaultKeymap, indentAndAutocompleteWithTab]),
        theme,
        saveUpdates(source)
      ]
    })

    this.view = new EditorView({
      state: state,
      parent: place
    })

    // Sincroniza escritas EXTERNAS no textarea (inserir bloco pronto, "Ajustar
    // com IA") de volta pro CodeMirror. Sem isso, o textarea muda mas a
    // EditorView fica com o MJML antigo — e ao editar na aba "Código MJML" o
    // saveUpdates grava o doc velho por cima, apagando em silêncio o que o
    // bloco ou a IA escreveram. A flag impede recursão com o saveUpdates
    // (view -> textarea, que dispara "change"); a checagem de igualdade evita
    // resetar o cursor a cada tecla digitada no próprio editor.
    const view = this.view
    let applyingExternal = false
    const syncFromSource = () => {
      if (applyingExternal) return
      const incoming = source.value
      if (incoming === view.state.doc.toString()) return
      applyingExternal = true
      view.dispatch({
        changes: { from: 0, to: view.state.doc.length, insert: incoming }
      })
      applyingExternal = false
    }
    source.addEventListener("input", syncFromSource)
    source.addEventListener("change", syncFromSource)

    document.getElementById("mjml-editor-toolbar").addEventListener("x-show-image-dialog", () => {
      document
        .querySelector("[data-dialog-for=image]")
        .dispatchEvent(new CustomEvent("x-show", { detail: {} }))
      window.addEventListener(
        "update-image",
        (e) => {
          const { src } = e.detail
          if (!src) {
            this.view.focus()
            return
          }
          this.view.dispatch(this.view.state.replaceSelection(src))
        },
        { once: true }
      )
    })
  }
}
