defmodule Keila.Media do
  @moduledoc """
  Context da biblioteca de mídia (imagens) por projeto.

  Cada projeto (academia/cliente) tem sua própria biblioteca isolada, hospedada
  no ImageKit. Esta camada coordena upload (via ImageKit), persistência da
  metadata local, listagem e exclusão.
  """

  import Ecto.Query
  alias Keila.Repo
  alias Keila.Media.Asset
  alias Keila.Integrations.ImageKit

  @max_file_size 10 * 1024 * 1024
  @allowed_mime_types ~w(image/png image/jpeg image/jpg image/webp image/gif image/svg+xml)

  @spec list_assets(binary(), keyword()) :: [Asset.t()]
  def list_assets(project_id, opts \\ []) do
    folder = Keyword.get(opts, :folder)

    Asset
    |> where([a], a.project_id == ^project_id)
    |> maybe_filter_folder(folder)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
  end

  defp maybe_filter_folder(query, nil), do: query

  defp maybe_filter_folder(query, folder),
    do: where(query, [a], a.folder == ^folder)

  @spec count_by_folder(binary()) :: %{String.t() => non_neg_integer()}
  def count_by_folder(project_id) do
    Asset
    |> where([a], a.project_id == ^project_id)
    |> group_by([a], a.folder)
    |> select([a], {a.folder, count(a.id)})
    |> Repo.all()
    |> Map.new()
  end

  @spec get_asset(binary()) :: Asset.t() | nil
  def get_asset(asset_id), do: Repo.get(Asset, asset_id)

  @doc """
  Faz upload de um arquivo pro ImageKit e cria o registro local.

  ## Argumentos
  - `project_id` — projeto dono da imagem
  - `upload` — `%Plug.Upload{}` ou map com :path, :filename, :content_type
  - `opts` — `:folder`, `:tags`, `:alt_text`, `:uploaded_by_user_id`
  """
  @spec upload_and_create(binary(), Plug.Upload.t() | map(), keyword()) ::
          {:ok, Asset.t()} | {:error, term()}
  def upload_and_create(project_id, upload, opts \\ []) do
    cond do
      not ImageKit.configured?() ->
        {:error,
         "ImageKit não está configurado. Configure as variáveis IMAGEKIT_PUBLIC_KEY, IMAGEKIT_PRIVATE_KEY e IMAGEKIT_URL_ENDPOINT no .env e reinicie o servidor."}

      is_nil(project_id) ->
        {:error, "Projeto não identificado"}

      true ->
        do_upload_and_create(project_id, upload, opts)
    end
  end

  defp do_upload_and_create(project_id, upload, opts) do
    folder = Keyword.get(opts, :folder, "geral")

    filename = get_upload_field(upload, :filename) || "imagem"
    content_type = get_upload_field(upload, :content_type)

    # Aceita 2 formatos:
    # 1) %{path: ...} → lê do disco (uso clássico)
    # 2) %{bytes: <binary>} → bytes já em memória (uso async no wizard)
    file_data_result =
      case upload do
        %{bytes: bytes} when is_binary(bytes) -> {:ok, bytes}
        %{path: path} when is_binary(path) -> File.read(path)
        _ -> {:error, "Upload sem path nem bytes"}
      end

    with :ok <- validate_upload_size_and_type(upload, content_type),
         {:ok, file_data} <- file_data_result,
         {:ok, imagekit_resp} <-
           ImageKit.upload_file(file_data, filename,
             folder: "/projects/#{project_id}/#{folder}",
             content_type: content_type
           ) do
      params = %{
        project_id: project_id,
        imagekit_file_id: imagekit_resp["fileId"],
        url: imagekit_resp["url"],
        thumbnail_url: imagekit_resp["thumbnailUrl"] || imagekit_resp["url"],
        filename: filename,
        mime_type: content_type || imagekit_resp["fileType"] || "application/octet-stream",
        size_bytes: imagekit_resp["size"],
        width: imagekit_resp["width"],
        height: imagekit_resp["height"],
        folder: folder,
        tags: Keyword.get(opts, :tags, []),
        alt_text: Keyword.get(opts, :alt_text),
        uploaded_by_user_id: Keyword.get(opts, :uploaded_by_user_id)
      }

      case params |> Asset.creation_changeset() |> Repo.insert() do
        {:ok, asset} ->
          {:ok, asset}

        {:error, changeset} ->
          # Se falhar no banco, deleta a imagem do ImageKit pra não deixar lixo
          _ = ImageKit.delete_file(imagekit_resp["fileId"])
          {:e