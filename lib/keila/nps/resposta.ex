defmodule Keila.Nps.Resposta do
  @moduledoc """
  Resposta de um contato a uma pesquisa de NPS (nota 0–10 + comentário).

  Categoria derivada da nota: 0–6 detrator, 7–8 neutro, 9–10 promotor.
  """
  use Keila.Schema, prefix: "npsr"

  alias Keila.Nps.Envio

  schema "nps_respostas" do
    field :nota, :integer
    field :categoria, :string
    field :comentario, :string
    field :respondido_em, :utc_datetime

    belongs_to :envio, Envio, type: Envio.Id

    timestamps()
  end

  @doc "Classifica uma nota 0–10 em categoria de NPS."
  def categoria(nota) when is_integer(nota) and nota >= 9, do: "promotor"
  def categoria(nota) when is_integer(nota) and nota >= 7, do: "neutro"
  def categoria(nota) when is_integer(nota) and nota >= 0, do: "detrator"

  @doc "Changeset para registrar uma resposta (deriva categoria e data)."
  def creation_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:envio_id, :nota, :comentario])
    |> validate_required([:envio_id, :nota])
    |> validate_number(:nota, greater_than_or_equal_to: 0, less_than_or_equal_to: 10)
    |> put_categoria()
    |> put_respondido_em()
    |> unique_constraint(:envio_id)
  end

  defp put_categoria(changeset) do
    case get_field(changeset, :nota) do
      nota when is_integer(nota) and nota >= 0 and nota <= 10 ->
        put_change(changeset, :categoria, categoria(nota))

      _ ->
        changeset
    end
  end

  defp put_respondido_em(changeset) do
    case get_field(changeset, :respondido_em) do
      nil ->
        put_change(changeset, :respondido_em, DateTime.utc_now() |> DateTime.truncate(:second))

      _ ->
        changeset
    end
  end
end
