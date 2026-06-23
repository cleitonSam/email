defmodule Keila.EmpresasKybTest do
  use Keila.DataCase, async: true
  alias Keila.Empresas
  alias Keila.Empresas.Empresa

  describe "pode_enviar?/1 (gate de KYB — regra nº 7)" do
    test "projeto sem empresa não é bloqueado (comportamento legado)" do
      assert Empresas.pode_enviar?(nil)
    end

    test "empresa ativa com KYB aprovado pode enviar" do
      assert Empresas.pode_enviar?(%Empresa{status: "ativa", kyb_status: "aprovado"})
      assert Empresas.pode_enviar?(%Empresa{status: "convidada", kyb_status: "aprovado"})
    end

    test "KYB pendente ou rejeitado bloqueia o envio" do
      refute Empresas.pode_enviar?(%Empresa{status: "ativa", kyb_status: "pendente"})
      refute Empresas.pode_enviar?(%Empresa{status: "ativa", kyb_status: "rejeitado"})
    end

    test "empresa bloqueada/cancelada não envia mesmo com KYB aprovado" do
      refute Empresas.pode_enviar?(%Empresa{status: "bloqueada", kyb_status: "aprovado"})
      refute Empresas.pode_enviar?(%Empresa{status: "cancelada", kyb_status: "aprovado"})
    end
  end

  describe "transições de KYB" do
    setup do
      _root = insert!(:group)
      user = insert!(:user)
      {:ok, project} = Keila.Projects.create_project(user.id, params(:project))

      empresa =
        Repo.insert!(%Empresa{
          nome: "ACME",
          cnpj: "11222333000181",
          email_responsavel: "dono@acme.com",
          status: "ativa",
          kyb_status: "pendente",
          project_id: project.id
        })

      %{empresa: empresa, user: user}
    end

    test "aprovar_kyb libera o envio e registra quem aprovou", %{empresa: empresa, user: user} do
      refute Empresas.pode_enviar?(empresa)

      assert {:ok, aprovada} = Empresas.aprovar_kyb(empresa, user.id)
      assert aprovada.kyb_status == "aprovado"
      assert aprovada.kyb_aprovado_por_id == user.id
      assert aprovada.kyb_aprovado_em
      assert Empresas.pode_enviar?(aprovada)
    end

    test "rejeitar_kyb mantém bloqueado e guarda o motivo", %{empresa: empresa, user: user} do
      assert {:ok, rejeitada} = Empresas.rejeitar_kyb(empresa, user.id, "Site fora do ar")
      assert rejeitada.kyb_status == "rejeitado"
      assert rejeitada.kyb_motivo_rejeicao == "Site fora do ar"
      refute Empresas.pode_enviar?(rejeitada)
    end

    test "bloquear/desbloquear alterna o status operacional", %{empresa: empresa, user: user} do
      {:ok, empresa} = Empresas.aprovar_kyb(empresa, user.id)
      assert Empresas.pode_enviar?(empresa)

      {:ok, bloqueada} = Empresas.bloquear(empresa)
      assert bloqueada.status == "bloqueada"
      refute Empresas.pode_enviar?(bloqueada)

      {:ok, reativada} = Empresas.desbloquear(bloqueada)
      assert reativada.status == "ativa"
      assert Empresas.pode_enviar?(reativada)
    end
  end
end
