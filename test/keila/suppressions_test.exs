defmodule Keila.SuppressionsTest do
  use Keila.DataCase, async: true
  alias Keila.{Suppressions, Projects}

  setup do
    _root = insert!(:group)
    user = insert!(:user)
    {:ok, project} = Projects.create_project(user.id, params(:project))
    %{project: project}
  end

  @tag :suppressions
  test "suprime e detecta supressão por empresa", %{project: project} do
    refute Suppressions.suprimido?("foo@bar.com", project.id)

    assert {:ok, _} =
             Suppressions.suprimir("foo@bar.com", project_id: project.id, reason: "hard_bounce")

    assert Suppressions.suprimido?("foo@bar.com", project.id)
  end

  @tag :suppressions
  test "supressão é case-insensitive / normalizada", %{project: project} do
    assert {:ok, _} =
             Suppressions.suprimir("  Foo@Bar.com ", project_id: project.id, reason: "manual")

    assert Suppressions.suprimido?("foo@bar.com", project.id)
    assert Suppressions.suprimido?("FOO@BAR.COM", project.id)
  end

  @tag :suppressions
  test "suprimir é idempotente", %{project: project} do
    assert {:ok, a} = Suppressions.suprimir("dup@bar.com", project_id: project.id, reason: "manual")
    assert {:ok, b} = Suppressions.suprimir("dup@bar.com", project_id: project.id, reason: "manual")
    assert a.id == b.id
    assert Suppressions.contar_por_projeto(project.id) == 1
  end

  @tag :suppressions
  test "bloqueio global vale para qualquer projeto", %{project: project} do
    assert {:ok, _} = Suppressions.suprimir("spam@bad.com", scope: :global, reason: "global_block")

    assert Suppressions.bloqueado_globalmente?("spam@bad.com")
    # mesmo sem supressão local, o global barra o envio neste projeto
    assert Suppressions.suprimido?("spam@bad.com", project.id)
  end

  @tag :suppressions
  test "remover apaga a supressão local", %{project: project} do
    assert {:ok, _} = Suppressions.suprimir("rm@bar.com", project_id: project.id, reason: "manual")
    assert Suppressions.suprimido?("rm@bar.com", project.id)

    Suppressions.remover("rm@bar.com", project.id)
    refute Suppressions.suprimido?("rm@bar.com", project.id)
  end
end
