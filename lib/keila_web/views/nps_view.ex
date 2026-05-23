defmodule KeilaWeb.NpsView do
  use KeilaWeb, :view

  # ── Datas ──────────────────────────────────────────────────────────────

  def format_date(nil), do: "—"
  def format_date(datetime), do: Calendar.strftime(datetime, "%d/%m/%Y")

  def format_datetime(nil), do: "—"
  def format_datetime(datetime), do: Calendar.strftime(datetime, "%d/%m/%Y %H:%M")

  # ── Status da pesquisa ─────────────────────────────────────────────────

  def status_label("rascunho"), do: "Rascunho"
  def status_label("ativa"), do: "Ativa"
  def status_label("encerrada"), do: "Encerrada"
  def status_label(other), do: other

  def status_classes("ativa"), do: "bg-emerald-500/15 text-emerald-300 border-emerald-500/20"
  def status_classes("encerrada"), do: "bg-gray-500/15 text-gray-300 border-gray-500/20"
  def status_classes(_), do: "bg-amber-500/15 text-amber-300 border-amber-500/20"

  # ── Categoria da resposta ──────────────────────────────────────────────

  def categoria_label("promotor"), do: "Promotor"
  def categoria_label("neutro"), do: "Neutro"
  def categoria_label("detrator"), do: "Detrator"
  def categoria_label(other), do: other

  def categoria_classes("promotor"), do: "bg-emerald-500/15 text-emerald-300 border-emerald-500/20"
  def categoria_classes("neutro"), do: "bg-amber-500/15 text-amber-300 border-amber-500/20"
  def categoria_classes("detrator"), do: "bg-rose-500/15 text-rose-300 border-rose-500/20"
  def categoria_classes(_), do: "bg-gray-500/15 text-gray-300 border-gray-500/20"

  # ── Faixa do score NPS ─────────────────────────────────────────────────

  @doc "Classe de cor do número do score, conforme a faixa."
  def score_color(score) when is_integer(score) do
    case Keila.Nps.faixa_score(score) do
      "critica" -> "text-rose-300"
      "aperfeicoamento" -> "text-amber-300"
      "qualidade" -> "text-fluxo-300"
      "excelencia" -> "text-emerald-300"
    end
  end

  @doc "Rótulo qualitativo da faixa do score."
  def faixa_label(score) when is_integer(score) do
    case Keila.Nps.faixa_score(score) do
      "critica" -> "Zona crítica"
      "aperfeicoamento" -> "Aperfeiçoamento"
      "qualidade" -> "Zona de qualidade"
      "excelencia" -> "Zona de excelência"
    end
  end

  @doc "Nome do contato de um envio, ou o e-mail como fallback."
  def nome_contato(nil), do: "—"

  def nome_contato(contato) do
    nome = String.trim("#{contato.first_name} #{contato.last_name}")
    if nome == "", do: contato.email, else: nome
  end

  @doc "Largura percentual de uma fatia, protegida contra divisão por zero."
  def pct(_parte, 0), do: 0
  def pct(parte, total), do: round(parte / total * 100)
end
