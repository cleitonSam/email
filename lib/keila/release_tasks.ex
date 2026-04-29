defmodule Keila.ReleaseTasks do
  @moduledoc """
  One-off commands you can run on Keila releases.

  Run the functions from this module like this:
  `bin/keila eval "Keila.ReleaseTasks.init()"`

  If you’re using the official Docker image, run them like this:
  `docker run pentacent/keila eval "Keila.ReleaseTasks.init()"`
  """

  @doc """
  Initializes the database and inserts fixtues.
  """
  def init() do
    migrate()

    Ecto.Migrator.with_repo(Keila.Repo, fn _ ->
      Code.eval_file(Path.join(:code.priv_dir(:keila), "repo/seeds.exs"))
      {:ok, :stop}
    end)
  end

  @doc """
  Runs database migrations.
  """
  def migrate do
    {:ok, _, _} = Ecto.Migrator.with_repo(Keila.Repo, &Ecto.Migrator.run(&1, :up, all: true))
  end

  @doc """
  Rolls back database migrations to given version.
  """
  def rollback(version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(Keila.Repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Creates a default SMTP sender for every project that has none.

  Reads configuration from environment variables:
    DEFAULT_SENDER_NAME  — display name (default: "Fluxo Digital Tech")
    DEFAULT_SENDER_EMAIL — from address
    DEFAULT_SMTP_HOST    — relay host (default: "smtp.hostinger.com")
    DEFAULT_SMTP_PORT    — port (default: 587)
    DEFAULT_SMTP_USER    — SMTP username (defaults to DEFAULT_SENDER_EMAIL)
    DEFAULT_SMTP_PASS    — SMTP password (required; skips if not set)
    DEFAULT_SMTP_TLS     — tls mode: "starttls" | "tls" | "none" (default: "starttls")
  """
  def ensure_default_sender do
    smtp_pass = System.get_env("DEFAULT_SMTP_PASS", "")

    if smtp_pass == "" do
      IO.puts("⚠️  DEFAULT_SMTP_PASS not set — skipping default sender creation")
    else
      from_name = System.get_env("DEFAULT_SENDER_NAME", "Fluxo Digital Tech")
      from_email = System.get_env("DEFAULT_SENDER_EMAIL", "ti@fluxodigitaltech.com.br")
      smtp_host = System.get_env("DEFAULT_SMTP_HOST", "smtp.hostinger.com")
      smtp_port = String.to_integer(System.get_env("DEFAULT_SMTP_PORT", "587"))
      smtp_user = System.get_env("DEFAULT_SMTP_USER", from_email)
      smtp_tls = System.get_env("DEFAULT_SMTP_TLS", "starttls")

      Ecto.Migrator.with_repo(Keila.Repo, fn _repo ->
        import Ecto.Query
        alias Keila.{Repo, Mailings.Sender, Projects.Project}

        projects = Repo.all(Project)

        Enum.each(projects, fn project ->
          existing = Repo.all(from(s in Sender, where: s.project_id == ^project.id))

          if Enum.empty?(existing) do
            params = %{
              "project_id" => project.id,
              "name" => from_name,
              "from_name" => from_name,
              "from_email" => from_email,
              "config" => %{
                "type" => "smtp",
                "smtp_relay" => smtp_host,
                "smtp_port" => smtp_port,
                "smtp_username" => smtp_user,
                "smtp_password" => smtp_pass,
                "smtp_auth_method" => "password",
                "smtp_tls_mode" => smtp_tls
              }
            }

            case Repo.insert(Sender.creation_changeset(%Sender{}, params)) do
              {:ok, sender} ->
                IO.puts("✅ Sender criado para #{project.name}: #{sender.id}")

              {:error, cs} ->
                IO.puts("❌ Erro no projeto #{project.name}: #{inspect(cs.errors)}")
            end
          else
            IO.puts("ℹ️  Projeto #{project.name} já tem sender, pulando.")
          end
        end)

        {:ok, :done}
      end)
    end
  end
end
