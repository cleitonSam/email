defmodule Keila.Projects.Brand do
  @moduledoc """
  Helper pra ler/escrever o brand kit de um projeto.

  Brand kit fica armazenado em `project.data["brand"]` como map:

      %{
        "name" => "Academia Movimento",
        "logo_url" => "https://ik.imagekit.io/.../logo.png",
        "color_primary" => "#FF5A1F",
        "color_dark" => "#0A0E27",
        "color_text" => "#1A1A1A",
        "color_accent" => "#C4FF00",
        "whatsapp_url" => "https://wa.me/...",
        "address" => "Rua X, 123",
        "completed_at" => "2026-04-28T22:00:00Z"
      }

  Esses valores são injetados nos templates MJML via Liquid:
  `{{ brand.color_primary }}`, `{{ brand.logo_url }}`, etc.
  """

  alias Keila.Projects
  alias Keila.Projects.Project

  @default_brand %{
    "name" => "",
    "logo_url" => "",
    "color_primary" => "#FF5A1F",
    "color_dark" => "#0A0E27",
    "color_text" => "#1A1A1A",
    "color_accent" => "#C4FF00",
    "whatsapp_url" => "",
    "address" => "",
    "completed_at" => nil
  }

  @spec get(Project.t()) :: map()
  def get(%Project{data: data}) when is_map(data) do
    brand = Map.get(data, "brand", %{})
    Map.merge(@default_brand, brand)
  end

  def get(_), do: @default_brand

  @spec update(Project.id(), map()) :: {:ok, Project.t()} | {:error, any()}
  def update(project_id, brand_attrs) when is_map(brand_attrs) do
    project = Projects.get_project(project_id)

    current_brand = get(project)
    new_brand = Map.merge(current_brand, stringify_keys(brand_attrs))
    new_data = Map.put(project.data || %{}, "brand", new_brand)

    Projects.update_project(project_id, %{data: new_data})
  end

  @spec mark_completed(Project.id()) :: {:ok, Project.t()} | {:error, any()}
  def mark_completed(project_id) do
    update(project_id, %{
      "completed_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  @spec completed?(Project.t()) :: boolean()
  def completed?(%Project{} = project) do
    case get(project) do
      %{"completed_at" => v} when is_binary(v) and v != "" -> true
      _ -> false
    end
  end

  def completed?(_), do: false

  @doc """
  Retorna brand assigns prontos pra usar em Liquid (templates MJML).
  Inclui defaults seguros pra cada campo.
  """
  @spec to_assigns(Project.t()) :: map()
  def to_assigns(project) do
    brand = get(project)
    %{"brand" => brand}
  end

  defp stringify_keys(map) do
    Enum.into(map, %{}, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
  end
end
