defmodule Keila.Auditoria.Log do
  @moduledoc """
  Registro imutável de uma ação crítica (trilha de auditoria).

  Ver `Keila.Auditoria` para a API de gravação/consulta.
  """
  use Keila.Schema, prefix: "al"

  alias Keila.Auth.User
  alias Keila.Projects.Project

  schema "audit_logs" do
    field :action, :string
    field :actor_email, :string
    field :entity_type, :string
    field :entity_id, :string
    field :ip, :string
    field :user_agent, :string
    field :metadata, :map, default: %{}

    belongs_to :actor_user, User, type: User.Id, foreign_key: :actor_user_id
    belongs_to :project, Project, type: Project.Id

    timestamps(updated_at: false)
  end

  @fields [
    :action,
    :actor_user_id,
    :actor_email,
    :entity_type,
    :entity_id,
    :project_id,
    :ip,
    :user_agent,
    :metadata
  ]

  @doc false
  def changeset(params) do
    %__MODULE__{}
    |> cast(params, @fields)
    |> validate_required([:action])
    |> validate_length(:user_agent, max: 500)
  end
end
