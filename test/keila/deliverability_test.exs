defmodule Keila.DeliverabilityTest do
  use Keila.DataCase, async: true
  alias Keila.Deliverability
  alias Keila.Deliverability.EmailDomain

  describe "domain_from_email/1" do
    test "extrai e normaliza o domínio" do
      assert Deliverability.domain_from_email("a@Empresa.COM.br") == "empresa.com.br"
      assert Deliverability.domain_from_email("marketing@x.io") == "x.io"
    end

    test "retorna nil para entrada inválida" do
      assert Deliverability.domain_from_email("sem-arroba") == nil
      assert Deliverability.domain_from_email(nil) == nil
    end
  end

  describe "valid_dmarc?/1" do
    test "aceita registro DMARC válido" do
      assert Deliverability.valid_dmarc?("v=DMARC1; p=none; rua=mailto:dmarc@x.com")
      assert Deliverability.valid_dmarc?("v=DMARC1; p=reject")
    end

    test "rejeita registros inválidos" do
      refute Deliverability.valid_dmarc?("v=spf1 include:x")
      # sem a tag obrigatória p=
      refute Deliverability.valid_dmarc?("v=DMARC1; rua=mailto:x@y.com")
      refute Deliverability.valid_dmarc?("")
    end
  end

  describe "normalize_domain/1" do
    test "remove protocolo, path e normaliza" do
      assert EmailDomain.normalize_domain(" HTTPS://Empresa.com.br/foo ") == "empresa.com.br"
    end
  end

  describe "dominio_liberado?/2 (gate progressivo)" do
    setup do
      _root = insert!(:group)
      user = insert!(:user)
      {:ok, project} = Keila.Projects.create_project(user.id, params(:project))
      %{project: project}
    end

    test "sem registro de domínio, libera (comportamento legado)", %{project: project} do
      assert Deliverability.dominio_liberado?(project.id, "x@semregistro.com")
    end

    test "from_email inválido também libera no modo não-estrito", %{project: project} do
      assert Deliverability.dominio_liberado?(project.id, nil)
    end

    test "domínio verificado libera; pendente bloqueia", %{project: project} do
      {:ok, _verified} =
        %{"project_id" => project.id, "domain" => "ok.com"}
        |> EmailDomain.creation_changeset()
        |> Ecto.Changeset.put_change(:status, "verified")
        |> Repo.insert()

      {:ok, _pending} =
        %{"project_id" => project.id, "domain" => "pend.com"}
        |> EmailDomain.creation_changeset()
        |> Repo.insert()

      assert Deliverability.dominio_liberado?(project.id, "a@ok.com")
      refute Deliverability.dominio_liberado?(project.id, "a@pend.com")
    end
  end
end
