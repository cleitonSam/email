defmodule Keila.Empresas.Empresa do
  @moduledoc """
  Empresa cliente da Fluxo — um tenant do sistema multi-empresa.

  Cada empresa tem CNPJ, nome e um Projeto isolado (workspace). É cadastrada
  pelo admin master, que dispara um convite por e-mail; ao aceitar o convite,
  a pessoa responsável vira dona do projeto da empresa.

  Status operacional:
    - "rascunho": cadastrada, ainda sem convite
    - "convidada": convite enviado, aguardando aceite
    - "ativa": convite aceito, empresa operando
    - "bloqueada": envio suspenso (reputação/abuso)
    - "cancelada": empresa encerrada

  Status de KYB (gate de liberação de envio — regra nº 7 do Prompt Mestre):
    - "pendente": aguardando validação do Master
    - "aprovado": KYB ok, liberada para disparar
    - "rejeitado": KYB recusado, não dispara
  """
  use Keila.Schema, prefix: "emp"

  alias Keila.Projects.Project
  alias Keila.Auth.User

  @statuses ~w(rascunho convidada ativa bloqueada cancelada)
  @kyb_statuses ~w(pendente aprovado rejeitado)
  @planos ~w(teste basico pro enterprise)

  schema "empresas" do
    field :nome, :string
    field :cnpj, :string
    field :status, :string, default: "convidada"
    field :email_responsavel, :string

    # Dados do responsável / comerciais
    field :responsavel_nome, :string
    field :telefone, :string
    field :segmento, :string
    field :site, :string
    field :observacoes, :string

    # Plano e limites de envio
    field :plano, :string, default: "teste"
    field :limite_diario, :integer
    field :limite_mensal, :integer

    # Domínio de envio
    field :dominio_principal, :string
    field :subdominio_envio, :string

    # LGPD — Encarregado/DPO
    field :dpo_nome, :string
    field :dpo_email, :string

    # KYB (Know Your Business)
    field :kyb_status, :string, default: "pendente"
    field :kyb_aprovado_em, :utc_datetime
    field :kyb_motivo_rejeicao, :string

    belongs_to :project, Project, type: Project.Id
    belongs_to :kyb_aprovado_por, User, type: User.Id, foreign_key: :kyb_aprovado_por_id
    belongs_to :criado_por, User, type: User.Id, foreign_key: :criado_por_id

    timestamps()
  end

  @creation_fields [
    :nome,
    :cnpj,
    :email_responsavel,
    :responsavel_nome,
    :telefone,
    :segmento,
    :site,
    :observacoes,
    :plano,
    :limite_diario,
    :limite_mensal,
    :project_id,
    :status,
    :criado_por_id
  ]

  @doc "Changeset para cadastrar uma nova empresa."
  def creation_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:nome, :cnpj, :email_responsavel])
    |> validate_format(:email_responsavel, ~r/@/, message: "E-mail inválido")
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:plano, @planos)
    |> validate_number(:limite_diario, greater_than_or_equal_to: 0)
    |> validate_number(:limite_mensal, greater_than_or_equal_to: 0)
    |> update_change(:cnpj, &only_digits/1)
    |> validate_cnpj()
    |> unique_constraint(:cnpj)
  end

  @doc "Changeset para atualizar dados/status da empresa."
  def update_changeset(struct, params) do
    struct
    |> cast(params, [
      :nome,
      :status,
      :responsavel_nome,
      :telefone,
      :segmento,
      :site,
      :observacoes,
      :plano,
      :limite_diario,
      :limite_mensal,
      :dominio_principal,
      :subdominio_envio,
      :dpo_nome,
      :dpo_email
    ])
    |> validate_required([:nome])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:plano, @planos)
  end

  @doc "Changeset para o resultado do KYB (aprovação/rejeição) feito pelo Master."
  def kyb_changeset(struct, params) do
    struct
    |> cast(params, [:kyb_status, :kyb_aprovado_em, :kyb_aprovado_por_id, :kyb_motivo_rejeicao])
    |> validate_inclusion(:kyb_status, @kyb_statuses)
  end

  @doc "Lista de status operacionais válidos."
  def statuses, do: @statuses

  @doc "Lista de status de KYB válidos."
  def kyb_statuses, do: @kyb_statuses

  @doc "Lista de planos válidos."
  def planos, do: @planos

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
