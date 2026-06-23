defmodule Keila.DataSubjectTest do
  use Keila.DataCase, async: true
  alias Keila.{DataSubject, Consent, Contacts, Projects, Suppressions}

  setup do
    _root = insert!(:group)
    user = insert!(:user)
    {:ok, project} = Projects.create_project(user.id, params(:project))
    {:ok, contact} = Contacts.create_contact(project.id, params(:contact))
    %{project: project, contact: contact, user: user}
  end

  test "criar vincula o pedido ao contato pelo e-mail", %{project: project, contact: contact} do
    {:ok, req} = DataSubject.criar(project.id, %{email: contact.email, request_type: "deletion"})
    assert req.contact_id == contact.id
    assert req.status == "pending"
    assert req.requested_at
  end

  test "request_type inválido falha", %{project: project} do
    assert {:error, _cs} = DataSubject.criar(project.id, %{email: "x@y.com", request_type: "xpto"})
  end

  test "anonimizar remove PII, descadastra e suprime o e-mail original", %{
    project: project,
    contact: contact
  } do
    original = contact.email

    {:ok, anon} = DataSubject.anonimizar_contato(contact)

    assert anon.first_name == nil
    assert anon.last_name == nil
    assert anon.status == :unsubscribed
    refute anon.email == original
    assert Suppressions.suprimido?(original, project.id)
  end

  test "exportar inclui histórico de consentimento", %{contact: contact} do
    {:ok, _} = Consent.registrar(contact: contact, source: "form", legal_basis: "consent")

    export = DataSubject.exportar_contato(contact)
    assert export.email == contact.email
    assert length(export.consent_history) == 1
  end
end
