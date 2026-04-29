defmodule Keila.Media.Asset do
  @moduledoc """
  Schema de uma imagem (asset) na biblioteca de mídia de um projeto.

  Cada projeto/academia tem sua própria biblioteca isolada — o asset é vinculado
  ao `project_id` e referencia o arquivo armazenado no ImageKit via
  `imagekit_file_id` + `url`.
  """
  use Keila.Schema, prefix: "ma"

  alias Keila.Projects.Project

  schema "media_assets" do
    field :imagekit_file_id, :string
    field :url, :string
    field :thumbnail_url, :string

    field :filename, :string
    field :mime_type, :string
    field :size_bytes, :integer
    field :width, :integer
    field :height, :integer

    field :folder, :string, default: "geral"
    field :tags, {:array, :string}, default: []
    field :alt_text, :string

    field :uploaded_by_user_id, Keila.Auth.User.Id

    belongs_to :project, Project, type: Project.Id

    timestamps()
  end

  @creation_fields [
    :project_id,
    :imagekit_file_id,
    :url,
    :thumbnail_url,
    :filename,
    :mime_type,
    :size_bytes,
    :width,
    :height,
    :folder,
    :tags,
    :alt_text,
    :uploaded_by_user_id
  ]

  @update_fields [:filename, :folder, :tags, :alt_text]

  @valid_folders ~w(geral logos fotos produtos hero avatares)

  @spec creation_changeset(map()) :: Ecto.Changeset.t(t())
  def creation_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:project_id, :imagekit_file_id, :url, :filename])
    |> validate_inclusion(:folder, @valid_folders,
      message: "Pasta inválida. Use: #{Enum.join(@valid_folders, ", ")}"
    )
    |> unique_constraint(:imagekit_file_id)
  end

  @spec update_changeset(t(), map()) :: Ecto.Changeset.t(t())
  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
    |> validate_inclusion(:folder, @valid_folders)
  end

  @spec valid_folders() :: [String.t()]
  def valid_folders, do: @valid_folders
end
