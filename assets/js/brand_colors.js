// Extração de cores do logo no navegador — sem dependência externa.
// Lê o logo via proxy same-origin (/b/:project_id/logo, servido pelo próprio
// app), desenha num canvas, quantiza os pixels e devolve a paleta dominante.
// O proxy ser same-origin é o que permite getImageData sem "tainted canvas".

function rgbToHex(r, g, b) {
  const h = (n) => Math.max(0, Math.min(255, Math.round(n))).toString(16).padStart(2, "0")
  return `#${h(r)}${h(g)}${h(b)}`
}

function luminance(r, g, b) {
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
}

function saturation(r, g, b) {
  const max = Math.max(r, g, b)
  const min = Math.min(r, g, b)
  return max === 0 ? 0 : (max - min) / max
}

function distance(a, b) {
  return Math.sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2)
}

function loadImage(url) {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => resolve(img)
    img.onerror = () => reject(new Error("falha ao carregar o logo"))
    img.src = url
  })
}

// Extrai { primary, accent, dark, extras } (todos em hex) de uma URL same-origin.
export async function extractPalette(url) {
  const img = await loadImage(url)
  const target = 64
  const ratio = Math.min(target / img.width, target / img.height, 1) || 1
  const canvas = document.createElement("canvas")
  canvas.width = Math.max(1, Math.round(img.width * ratio))
  canvas.height = Math.max(1, Math.round(img.height * ratio))
  const ctx = canvas.getContext("2d")
  ctx.drawImage(img, 0, 0, canvas.width, canvas.height)
  const { data } = ctx.getImageData(0, 0, canvas.width, canvas.height)

  // Agrupa cores em buckets grossos (4 bits/canal) contando frequência e
  // quanto cada bucket é "fundo" (quase-branco/quase-preto/transparente).
  const buckets = new Map()
  for (let i = 0; i < data.length; i += 4) {
    const r = data[i]
    const g = data[i + 1]
    const b = data[i + 2]
    const a = data[i + 3]
    if (a < 128) continue
    const nearWhite = r > 244 && g > 244 && b > 244
    const nearBlack = r < 12 && g < 12 && b < 12
    const key = `${r >> 4},${g >> 4},${b >> 4}`
    const e = buckets.get(key) || { r: 0, g: 0, b: 0, n: 0, bg: 0 }
    e.r += r
    e.g += g
    e.b += b
    e.n += 1
    if (nearWhite || nearBlack) e.bg += 1
    buckets.set(key, e)
  }

  const average = (e) => ({
    r: Math.round(e.r / e.n),
    g: Math.round(e.g / e.n),
    b: Math.round(e.b / e.n),
    n: e.n,
    bgRatio: e.bg / e.n
  })

  let entries = [...buckets.values()].map(average).filter((e) => e.bgRatio < 0.6)
  if (entries.length === 0) entries = [...buckets.values()].map(average)
  if (entries.length === 0) throw new Error("logo sem cores legíveis")

  // Score = frequência ponderada pela saturação → prioriza a cor de marca.
  const scored = entries
    .map((e) => ({ ...e, score: e.n * (0.4 + saturation(e.r, e.g, e.b)) }))
    .sort((a, b) => b.score - a.score)

  const primary = scored[0]

  // Accent: a cor mais bem pontuada que seja visualmente distante da primária.
  const accent =
    scored
      .slice(1)
      .filter((e) => distance([e.r, e.g, e.b], [primary.r, primary.g, primary.b]) > 60)
      .sort((a, b) => b.score - a.score)[0] ||
    scored[1] ||
    primary

  // Dark: cor escura prominente; se não houver, escurece a primária.
  let dark = [...entries].sort(
    (a, b) => luminance(a.r, a.g, a.b) - luminance(b.r, b.g, b.b)
  )[0]
  if (!dark || luminance(dark.r, dark.g, dark.b) > 90) {
    dark = { r: primary.r * 0.25, g: primary.g * 0.25, b: primary.b * 0.25 }
  }

  // Extras: até 5 cores distintas entre si, por score.
  const extras = []
  for (const e of scored) {
    if (extras.every((x) => distance([x.r, x.g, x.b], [e.r, e.g, e.b]) > 50)) extras.push(e)
    if (extras.length >= 5) break
  }

  return {
    primary: rgbToHex(primary.r, primary.g, primary.b),
    accent: rgbToHex(accent.r, accent.g, accent.b),
    dark: rgbToHex(dark.r, dark.g, dark.b),
    extras: extras.map((e) => rgbToHex(e.r, e.g, e.b))
  }
}

function setColor(name, hex) {
  if (!hex) return
  const input = document.querySelector(`input[name="${name}"]`)
  if (!input) return
  input.value = hex
  input.dispatchEvent(new Event("input", { bubbles: true }))
  input.dispatchEvent(new Event("change", { bubbles: true }))
}

// Liga o botão "Extrair cores do logo" da página de marca (dead view).
export function initBrandColors() {
  const btn = document.querySelector("[data-extract-colors]")
  if (!btn) return
  const status = document.querySelector("[data-extract-status]")

  btn.addEventListener("click", async () => {
    const url = btn.getAttribute("data-logo-url")
    if (!url) return
    btn.disabled = true
    if (status) status.textContent = "Extraindo cores do logo…"
    try {
      const palette = await extractPalette(url)
      setColor("brand[color_primary]", palette.primary)
      setColor("brand[color_accent]", palette.accent)
      setColor("brand[color_dark]", palette.dark)
      palette.extras.forEach((hex, i) => setColor(`brand[extra_${i}]`, hex))
      if (status) status.textContent = "✓ Cores extraídas do logo. Revise e salve."
    } catch (e) {
      if (status) status.textContent = "Não consegui ler as cores do logo — ajuste manualmente."
    } finally {
      btn.disabled = false
    }
  })
}
