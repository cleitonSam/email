defmodule Keila.Nps.Pesquisa do
  @moduledoc """
  Pesquisa de NPS — pertence a um projeto (empresa), isolada por projeto.

  Status: "rascunho" | "ativa" | "encerrada".
  """
  use Keila.Schema, prefix: "nps"

  alias Keila.Projects.Project

  @statuses ~w(rascunho ativa encerrada)
  @pergunta_padrao "Em uma escala de 0 a 10, o quanto você recomendaria a nossa empresa a um amigo ou colega?"

  schema "nps_pesquisas" do
    field :nome, :string
    field :pergunta, :string, default: @pergunta_padrao
    field :status, :string, default: "rascunho"

    belongs_to :project, Project, type: Project.Id

    timestamps()
  end

  @doc "Pergunta padrão de NPS."
  def pergunta_padrao, do: @pergunta_padrao

  @doc "Changeset para criar uma pesquisa."
  def creation_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:nome, :pergunta, :status, :project_id])
    |> maybe_pergunta_padrao()
    |> validate_required([:nome, :pergunta, :project_id])
    |> validate_inclusion(:status, @statuses)
  end

  @doc "Changeset para atualizar uma pesquisa."
  def update_changeset(struct, params) do
    struct
    |> cast(params, [:nome, :pergunta, :status])
    |> maybe_pergunta_padrao()
    |> validate_required([:nome, :pergunta])
    |> validate_inclusion(:status, @statuses)
  end

  defp maybe_pergunta_padrao(changeset) do
    case get_field(changeset, :pergunta) do
      nil -> put_change(changeset, :pergunta, @pergunta_padrao)
      "" -> put_change(changeset, :pergunta, @pergunta_padrao)
      _ -> changeset
    end
  end
end
