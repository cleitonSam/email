defmodule Keila.Repo.Migrations.CreateSuppressions do
  use Ecto.Migration

  @moduledoc """
  Lista de supressão (regra inegociável nº 3 + LGPD § 4 do Prompt Mestre).

  Trava dura que impede envio. Diferente do `status` do contato, a supressão é
  por e-mail (sobrevive à recriação/reimportação do contato) e pode ser:

    - `project_id` preenchido  → supressão local da empresa
    - `project_id` nulo        → bloqueio GLOBAL (vale para todas as empresas)

  `reason`: hard_bounce | complaint | unsubscribe | manual | global_block
  `email` é normalizado (lowercase/trim) pela aplicação antes de gravar.
  """

  def change do
    create table("suppressions") do
      add :email, :citext, null: false
      add :project_id, references("projects", on_delete: :delete_all)
      add :reason, :string, null: false
      add :source, :string
      add :notes, :text

      timestamps(updated_at: false)
    end

    # Um e-mail não pode estar suprimido duas vezes no mesmo escopo.
    # Índice parcial para supressão por empresa...
    create unique_index("suppressions", [:project_id, :email],
             where: "project_id IS NOT NULL",
             name: :suppressions_project_email_index
           )

    # ...e índice parcial para o bloqueio global (project_id nulo).
    create unique_index("suppressions", [:email],
             where: "project_id IS NULL",
             name: :suppressions_global_email_index
           )

    create index("suppressions", [:email])
    create index("suppressions", [:reason])
  end
end
