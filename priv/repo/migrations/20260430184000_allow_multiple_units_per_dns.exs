defmodule Keila.Repo.Migrations.AllowMultipleUnitsPerDns do
  use Ecto.Migration

  def change do
    # Remove o índice único que impedia o mesmo DNS de aparecer 2 vezes no projeto
    drop unique_index("evo_units", [:project_id, :evo_dns])
    
    # Adiciona um índice comum (não único) para performance
    create index("evo_units", [:project_id, :evo_dns])
    
    # Opcional: Garante que o nome da unidade seja único por projeto para não confundir o usuário
    create unique_index("evo_units", [:project_id, :name])
  end
end
