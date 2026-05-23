defmodule Keila.Empresas.Empresa do
  @moduledoc """
  Empresa cliente da Fluxo — um tenant do sistema multi-empresa.

  Cada empresa tem CNPJ, nome e um Projeto isolado (workspace). É cadastrada
  pelo admin master, que dispara um convite por e-mail; ao aceitar o convite,
  a pessoa responsável vira dona do projeto da empresa.

  Status:
    - "convidada": cadastrada, convite enviado, aguardando aceite
    - "ativa": convite aceito, empresa operando
  """
  use Keila.Schema, prefix: "emp"

  alias Keila.Projects.Project

  @statuses ~w(convidada ativa)

  schema "empresas" do
    field :nome, :string
    field :cnpj, :string
    field :status, :string, default: "convidada"
    field :email_responsavel, :string

    belongs_to :project, Project, type: Project.Id

    timestamps()
  end

  @creation_fields [:nome, :cnpj, :email_responsavel, :project_id, :status]

  @doc "Changeset para cadastrar uma nova empresa."
  def creation_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:nome, :cnpj])
    |> validate_inclusion(:status, @statuses)
    |> update_change(:cnpj, &only_digits/1)
    |> validate_cnpj()
    |> unique_constraint(:cnpj)
  end

  @doc "Changeset para atualizar dados/status da empresa."
  def update_changeset(struct, params) do
    struct
    |> cast(params, [:nome, :status])
    |> validate_required([:nome])
    |> validate_inclusion(:status, @statuses)
  end

  @doc "Valida um CNPJ: 14 dígitos e dígitos verificadores corretos."
  def valid_cnpj?(cnpj) when is_binary(cnpj) do
    digits = only_digits(cnpj)

    cond do
      String.length(digits) != 14 -> false
      String.duplicate(String.first(digits), 14) == digits -> false
      true -> check_digits(digits)
    end
  end

  def valid_cnpj?(_), do: false

  defp only_digits(nil), do: nil
  defp only_digits(value), do: String.replace(value, ~r/[^0-9]/, "")

  defp validate_cnpj(changeset) do
    case get_field(changeset, :cnpj) do
      nil ->
        changeset

      cnpj ->
        if valid_cnpj?(cnpj),
          do: changeset,
          else: add_error(changeset, :cnpj, "CNPJ inválido")
    end
  end

  defp check_digits(digits) do
    nums = digits |> String.graphemes() |> Enum.map(&String.to_integer/1)
    {base, [d1, d2]} = Enum.split(nums, 12)

    check_digit(base, [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]) == d1 and
      check_digit(base ++ [d1], [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]) == d2
  end

  defp check_digit(nums, weights) do
    sum =
      nums
      |> Enum.zip(weights)
      |> Enum.reduce(0, fn {n, w}, acc -> acc + n * w end)

    r = rem(sum, 11)
    if r < 2, do: 0, else: 11 - r
  end
end
