defmodule Keila.Deliverability.EmailDomain do
  @moduledoc """
  Domínio de envio de um projeto/empresa e o estado da verificação de DNS.

  Ver `Keila.Deliverability` para a API de verificação e o gate de envio.

  Status:
    - "pending":  cadastrado, ainda não verificado
    - "verified": SPF + DMARC válidos (pode disparar)
    - "failed":   última checagem falhou (não libera)
  """
  use Keila.Schema, prefix: "edom"

  alias Keila.Projects.Project

  @statuses ~w(pending verified failed)

  schema "email_domains" do
    field :domain, :string
    field :status, :string, default: "pending"

    field :spf_ok, :boolean
    field :dmarc_ok, :boolean
    field :dkim_ok, :boolean
    field :dkim_selector, :string

    field :last_checked_at, :utc_datetime
    field :last_error, :string

    belongs_to :project, Project, type: Project.Id

    timestamps()
  end

  @domain_regex ~r/^(?=.{1,253}$)(?!-)([a-z0-9-]{1,63}\.)+[a-z]{2,}$/

  @doc "Changeset para cadastrar um domínio de envio."
  def creation_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:project_id, :domain, :dkim_selector])
    |> validate_required([:project_id, :domain])
    |> update_change(:domain, &normalize_domain/1)
    |> validate_format(:domain, @domain_regex, message: "Domínio inválido")
    |> unique_constraint([:project_id, :domain])
  end

  @doc "Changeset para gravar o resultado de uma verificação de DNS."
  def check_changeset(struct, params) do
    struct
    |> cast(params, [
      :status,
      :spf_ok,
      :dmarc_ok,
      :dkim_ok,
      :dkim_selector,
      :last_checked_at,
      :last_error
    ])
    |> validate_inclusion(:status, @statuses)
  end

  @doc "Normaliza um domínio (trim + lowercase, remove protocolo/path se vier colado)."
  def normalize_domain(nil), do: nil

  def normalize_domain(domain) when is_binary(domain) do
    domain
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r{^https?://}, "")
    |> String.replace(~r{/.*$}, "")
  end

  def statuses, do: @statuses
end
