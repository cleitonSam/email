defmodule Keila.RbacTest do
  use Keila.DataCase, async: true
  alias Keila.{Auth, Rbac, Projects}

  setup do
    _root = insert!(:group)
    owner = insert!(:user)
    {:ok, project} = Projects.create_project(owner.id, params(:project))
    :ok = Auth.ensure_company_roles!()
    %{project: project, owner: owner}
  end

  test "ensure_company_roles! é idempotente" do
    assert Auth.ensure_company_roles!() == :ok
    assert Auth.ensure_company_roles!() == :ok
    assert "owner" in Auth.company_role_names()
    assert "compliance" in Auth.company_role_names()
  end

  test "usuário sem papel atribuído tem acesso total (legado)", %{project: project, owner: owner} do
    refute Rbac.has_company_role?(owner.id, project.group_id)
    assert Rbac.can?(owner.id, project, "manage_company_domain")
    assert Rbac.can?(owner.id, project, "manage_campaigns")
  end

  test "viewer só visualiza relatórios", %{project: project} do
    user = insert!(:user)
    :ok = Auth.assign_company_role(user.id, project.group_id, "viewer")

    assert Rbac.has_company_role?(user.id, project.group_id)
    assert Rbac.can?(user.id, project, "view_reports")
    refute Rbac.can?(user.id, project, "manage_company_domain")
    refute Rbac.can?(user.id, project, "manage_campaigns")
  end

  test "operator gerencia campanhas mas não domínio/usuários", %{project: project} do
    user = insert!(:user)
    :ok = Auth.assign_company_role(user.id, project.group_id, "operator")

    assert Rbac.can?(user.id, project, "manage_campaigns")
    assert Rbac.can?(user.id, project, "manage_contacts")
    refute Rbac.can?(user.id, project, "manage_company_domain")
    refute Rbac.can?(user.id, project, "manage_company_users")
  end

  test "owner pode tudo", %{project: project} do
    user = insert!(:user)
    :ok = Auth.assign_company_role(user.id, project.group_id, "owner")

    assert Rbac.can?(user.id, project, "manage_company_domain")
    assert Rbac.can?(user.id, project, "manage_company_users")
    assert Rbac.can?(user.id, project, "view_compliance_logs")
  end

  test "assign_company_role com papel inexistente retorna erro", %{project: project} do
    user = insert!(:user)
    assert {:error, :role_not_found} = Auth.assign_company_role(user.id, project.group_id, "xpto")
  end
end
