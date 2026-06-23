defmodule Keila.ConsentTest do
  use Keila.DataCase, async: true
  alias Keila.{Consent, Contacts, Projects}

  setup do
    _root = insert!(:group)
    user = insert!(:user)
    {:ok, project} = Projects.create_project(user.id, params(:project))
    {:ok, contact} = Contacts.create_contact(project.id, params(:contact))
    %{project: project, contact: contact}
  end

  test "registra prova de consentimento e lista o histórico", %{contact: contact} do
    assert {:ok, log} =
             Consent.registrar(
               contact: contact,
               source: "form",
               legal_basis: "consent",
               double_opt_in: true,
               ip: "1.2.3.4",
               consent_text: "Aceito receber e-mails"
             )

    assert log.contact_id == contact.id
    assert log.email == contact.email
    assert log.legal_basis == "consent"
    assert log.double_opt_in == true

    logs = Consent.historico_por_contato(contact.id)
    assert length(logs) == 1
    assert hd(logs).source == "form"
  end

  test "base legal inválida não grava", %{contact: contact} do
    assert :error = Consent.registrar(contact: contact, legal_basis: "xpto")
  end
end
