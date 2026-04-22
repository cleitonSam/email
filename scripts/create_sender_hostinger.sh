#!/bin/bash
# Cria o sender Hostinger em todos os projetos que ainda não têm sender
# Rodar dentro do container: bash scripts/create_sender_hostinger.sh

bin/keila rpc '
alias Keila.{Repo, Mailings}
import Ecto.Query

projects = Repo.all(Keila.Projects.Project)

Enum.each(projects, fn project ->
  existing = Repo.all(from s in Mailings.Sender, where: s.project_id == ^project.id)

  if Enum.empty?(existing) do
    params = %{
      "name" => "Fluxo Digital Tech",
      "from_name" => "Fluxo Digital Tech",
      "from_email" => "ti@fluxodigitaltech.com.br",
      "config" => %{
        "type" => "smtp",
        "smtp_relay" => "smtp.hostinger.com",
        "smtp_port" => 587,
        "smtp_username" => "ti@fluxodigitaltech.com.br",
        "smtp_password" => "68141096Clei@",
        "smtp_auth_method" => "password",
        "smtp_tls_mode" => "starttls"
      }
    }

    case Mailings.create_sender(project.id, params) do
      {:ok, sender} ->
        IO.puts("✅ Sender criado para projeto #{project.name}: #{sender.id}")
      {:action_required, sender} ->
        IO.puts("⚠️  Sender criado (requer verificação) para #{project.name}: #{sender.id}")
      {:error, changeset} ->
        IO.puts("❌ Erro no projeto #{project.name}: #{inspect(changeset.errors)}")
    end
  else
    IO.puts("ℹ️  Projeto #{project.name} já tem #{length(existing)} sender(s), pulando.")
  end
end)
'
