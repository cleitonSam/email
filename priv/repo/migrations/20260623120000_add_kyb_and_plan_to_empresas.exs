defmodule Keila.Repo.Migrations.AddKybAndPlanToEmpresas do
  use Ecto.Migration

  @moduledoc """
  Expande `empresas` para suportar o gate de KYB (Know Your Business) e os dados
  comerciais/de governança que o Master Admin controla:

    - KYB: status (pendente/aprovado/rejeitado), quem aprovou/rejeitou, quando e
      por quê. Enquanto não aprovado, a empresa NÃO pode disparar (gate no worker).
    - Comercial: plano, limite diário e mensal de envio.
    - Domínio: domínio principal e subdomínio de envio próprio (reputação isolada).
    - LGPD: DPO/Encarregado por empresa.
    - Operacional: responsável, telefone, segmento, observações internas, criado_por.
  """

  def change do
    alter table("empresas") do
      # Dados do responsável / comerciais
      add :responsavel_nome, :string
      add :telefone, :string
      add :segmento, :string
      add :site, :string
      add :observacoes, :text

      # Plano e limites de envio
      add :plano, :string, default: "teste", null: false
      add :limite_diario, :integer
      add :limite_mensal, :integer

      # Domínio de envio
      add :dominio_principal, :string
      add :subdominio_envio, :string

      # LGPD — Encarregado/DPO
      add :dpo_nome, :string
      add :dpo_email, :string

      # KYB (Know Your Business)
      add :kyb_status, :string, default: "pendente", null: false
      add :kyb_aprovado_em, :utc_datetime
      add :kyb_aprovado_por_id, references("users", on_delete: :nilify_all)
      add :kyb_motivo_rejeicao, :text

      # Quem cadastrou (Master Admin)
      add :criado_por_id, references("users", on_delete: :nilify_all)
    end

    create index("empresas", [:kyb_status])
    create index("empresas", [:status])

    # Grandfathering: empresas que já existiam (e já operavam) entram como KYB
    # aprovado, para o novo gate de envio não bloqueá-las. Empresas novas nascem
    # "pendente" (default da coluna) e precisam de aprovação do Master.
    execute(
      "UPDATE empresas SET kyb_status = 'aprovado', kyb_aprovado_em = NOW()",
      "UPDATE empresas SET kyb_status = 'pendente'"
    )
  end
end
