defmodule Keila.Nps do
  @moduledoc """
  Context do NPS por e-mail.

  Tudo aqui é escopado por projeto (empresa) — uma empresa nunca enxerga
  pesquisa, envio ou resposta de outra. As funções de pesquisa recebem
  `project_id` e filtram por ele; envios e respostas herdam o escopo da
  pesquisa.

  Fluxo: cria-se uma `Pesquisa` → dispara-se `Envio`s aos contatos (cada um
  com token único) → o contato abre `/nps/:token` e grava uma `Resposta` →
  o dashboard agrega o score.
  """
  import Ecto.Query
  alias Keila.Repo
  alias Keila.Nps.{Pesquisa, Envio, Resposta}

  # ── Pesquisas ──────────────────────────────────────────────────────────

  @doc "Lista as pesquisas de um projeto, mais recentes primeiro."
  def list_pesquisas(project_id) do
    Pesquisa
    |> where([p], p.project_id == ^project_id)
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
  end

  @doc "Busca uma pesquisa pelo id (sem escopo — uso interno)."
  def get_pesquisa(id), do: Repo.get(Pesquisa, id)

  @doc """
  Busca uma pesquisa garantindo que pertence ao projeto informado.
  Retorna `nil` se não existir ou for de outro projeto.
  """
  def get_project_pesquisa(project_id, id) do
    Repo.one(from p in Pesquisa, where: p.id == ^id and p.project_id == ^project_id)
  end

  @doc "Cria uma pesquisa dentro de um projeto."
  def create_pesquisa(project_id, params) do
    params
    |> stringify()
    |> Map.put("project_id", project_id)
    |> Pesquisa.creation_changeset()
    |> Repo.insert()
  end

  @doc "Atualiza nome/pergunta/status de uma pesquisa."
  def update_pesquisa(%Pesquisa{} = pesquisa, params) do
    pesquisa
    |> Pesquisa.update_changeset(stringify(params))
    |> Repo.update()
  end

  @doc "Apaga uma pesquisa (envios e respostas caem em cascata)."
  def delete_pesquisa(%Pesquisa{} = pesquisa), do: Repo.delete(pesquisa)

  @doc "Changeset em branco para formulários."
  def change_pesquisa(%Pesquisa{} = pesquisa \\ %Pesquisa{}, params \\ %{}) do
    Pesquisa.update_changeset(pesquisa, stringify(params))
  end

  # ── Envios ─────────────────────────────────────────────────────────────

  @doc "Lista os envios de uma pesquisa, com o contato pré-carregado."
  def list_envios(pesquisa_id) do
    Envio
    |> where([e], e.pesquisa_id == ^pesquisa_id)
    |> order_by([e], desc: e.inserted_at)
    |> preload(:contato)
    |> Repo.all()
  end

  @doc """
  Busca um envio pelo token público, com pesquisa e resposta pré-carregadas.
  É o que a página `/nps/:token` usa.
  """
  def get_envio_by_token(token) when is_binary(token) and token != "" do
    Envio
    |> where([e], e.token == ^token)
    |> preload([:pesquisa, :resposta])
    |> Repo.one()
  end

  def get_envio_by_token(_), do: nil

  @doc """
  Cria os envios de uma pesquisa para uma lista de contatos.

  Ignora contatos que já têm envio nessa pesquisa (não duplica). Retorna
  `{:ok, envios_criados}` — uma lista só com os envios novos.
  """
  def criar_envios(%Pesquisa{} = pesquisa, contato_ids) when is_list(contato_ids) do
    ja_enviados =
      Envio
      |> where([e], e.pesquisa_id == ^pesquisa.id)
      |> select([e], e.contato_id)
      |> Repo.all()
      |> MapSet.new()

    novos =
      contato_ids
      |> Enum.uniq()
      |> Enum.reject(&MapSet.member?(ja_enviados, &1))

    envios =
      Enum.map(novos, fn contato_id ->
        {:ok, envio} =
          Envio.creation_changeset(%{
            "pesquisa_id" => pesquisa.id,
            "contato_id" => contato_id
          })
          |> Repo.insert()

        envio
      end)

    {:ok, envios}
  end

  @doc "Marca um envio como enviado, gravando o horário."
  def marcar_enviado(%Envio{} = envio) do
    envio
    |> Envio.status_changeset("enviado")
    |> Ecto.Changeset.put_change(:enviado_em, now())
    |> Repo.update()
  end

  @doc "Marca um envio como bounce (falha de entrega)."
  def marcar_bounce(%Envio{} = envio) do
    envio |> Envio.status_changeset("bounce") |> Repo.update()
  end

  # ── Respostas ──────────────────────────────────────────────────────────

  @doc "Indica se um envio já foi respondido."
  def respondido?(%Envio{} = envio) do
    Repo.exists?(from r in Resposta, where: r.envio_id == ^envio.id)
  end

  @doc """
  Registra a resposta de um envio: grava nota + comentário e marca o envio
  como respondido. Recusa se o envio já tiver resposta.
  """
  def registrar_resposta(%Envio{} = envio, params) do
    if respondido?(envio) do
      {:error, :ja_respondido}
    else
      params = stringify(params) |> Map.put("envio_id", envio.id)

      Repo.transaction(fn ->
        with {:ok, resposta} <- params |> Resposta.creation_changeset() |> Repo.insert(),
             {:ok, _envio} <-
               envio |> Envio.status_changeset("respondido") |> Repo.update() do
          resposta
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
    end
  end

  @doc "Lista as respostas de uma pesquisa, mais recentes primeiro."
  def list_respostas(pesquisa_id) do
    from(r in Resposta,
      join: e in Envio,
      on: e.id == r.envio_id,
      where: e.pesquisa_id == ^pesquisa_id,
      order_by: [desc: r.respondido_em],
      preload: [envio: :contato]
    )
    |> Repo.all()
  end

  # ── Estatísticas ───────────────────────────────────────────────────────

  @doc """
  Agrega o resultado de uma pesquisa.

  Retorna um mapa com: total de envios, respostas, contagem por categoria,
  taxa de resposta (%) e o score NPS (-100 a 100).
  """
  def estatisticas(pesquisa_id) do
    total_envios =
      Repo.one(from e in Envio, where: e.pesquisa_id == ^pesquisa_id, select: count(e.id))

    por_categoria =
      from(r in Resposta,
        join: e in Envio,
        on: e.id == r.envio_id,
        where: e.pesquisa_id == ^pesquisa_id,
        group_by: r.categoria,
        select: {r.categoria, count(r.id)}
      )
      |> Repo.all()
      |> Map.new()

    promotores = Map.get(por_categoria, "promotor", 0)
    neutros = Map.get(por_categoria, "neutro", 0)
    detratores = Map.get(por_categoria, "detrator", 0)
    respostas = promotores + neutros + detratores

    score =
      if respostas > 0 do
        round((promotores - detratores) / respostas * 100)
      else
        0
      end

    taxa_resposta =
      if total_envios > 0 do
        round(respostas / total_envios * 100)
      else
        0
      end

    %{
      total_envios: total_envios,
      respostas: respostas,
      promotores: promotores,
      neutros: neutros,
      detratores: detratores,
      score: score,
      taxa_resposta: taxa_resposta
    }
  end

  @doc """
  Classifica um score NPS numa faixa qualitativa.
  Crítica < 0 · Aperfeiçoamento 0–49 · Qualidade 50–74 · Excelência 75–100.
  """
  def faixa_score(score) when is_integer(score) do
    cond do
      score < 0 -> "critica"
      score < 50 -> "aperfeicoamento"
      score < 75 -> "qualidade"
      true -> "excelencia"
    end
  end

  # ── Helpers ────────────────────────────────────────────────────────────

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp stringify(params) do
    Map.new(params, fn {k, v} -> {to_string(k), v} end)
  end
end
