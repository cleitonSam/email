import BlockEditor from "../campaign-editors/block"
import { MarkdownEditor } from "../campaign-editors/markdown"
import MarkdownSimpleEditor from "../campaign-editors/markdown-simple"
import MjmlEditor from "../campaign-editors/mjml"

// Placeholder usado quando uma imagem falha no preview (mesmo formato visual
// dos templates pra não chamar atenção pro problema na hora de revisar).
const IMG_FALLBACK = "https://placehold.co/280x88/0A0E27/FFFFFF/png?text=LOGO"

// Injeta onerror em cada <img> do HTML do email. Se a imagem falhar
// (logo do ImageKit com restrição, asset removido, etc.), aparece o
// placeholder em vez do ícone "imagem quebrada". Só afeta o PREVIEW —
// o email enviado ao destinatário não roda JS.
const addImageFallback = (html) => {
  const handler = `this.onerror=null;this.src='${IMG_FALLBACK}';`
  return html.replace(/<img\b/gi, `<img onerror="${handler}"`)
}

const putHtmlPreview = (el) => {
  const raw = el.innerText
  if (!raw) return

  const content = addImageFallback(raw)

  const iframes = document.querySelectorAll(el.dataset.iframe)
  if (!iframes.length) return

  for (let i = 0; i < iframes.length; i++) {
    const iframe = iframes[i]
    const scrollX = iframe.contentWindow.scrollX
    const scrollY = iframe.contentWindow.scrollY
    const doc = iframe.contentDocument
    doc.open()
    doc.write(content)
    doc.close()
    iframe.contentWindow.scrollTo(scrollX, scrollY)
  }
}

const MarkdownSimpleEditorHook = {
  mounted() {
    new MarkdownSimpleEditor(this.el)
  }
}

const MarkdownEditorHook = {
  mounted() {
    let place = this.el.querySelector(".editor")
    new MarkdownEditor(place, document.querySelector("#campaign_text_body"))
  }
}

const BlockEditorHook = {
  mounted() {
    let place = this.el.querySelector(".editor")
    new BlockEditor(place, document.querySelector("#campaign_json_body"))
  }
}

const MjmlEditorHook = {
  mounted() {
    let place = this.el.querySelector(".editor")
    new MjmlEditor(place, document.querySelector("#campaign_mjml_body"))
  }
}

const HtmlPreviewHook = {
  mounted() {
    putHtmlPreview(this.el)
  },
  updated() {
    putHtmlPreview(this.el)
  }
}

export {
  BlockEditorHook as BlockEditor,
  HtmlPreviewHook as HtmlPreview,
  MarkdownEditorHook as MarkdownEditor,
  MarkdownSimpleEditorHook as MarkdownSimpleEditor,
  MjmlEditorHook as MjmlEditor
}
