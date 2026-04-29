defmodule KeilaWeb.ProjectAdminController do
  use KeilaWeb, :controller
  alias Keila.{Projects, Auth, Repo}
  alias Keila.Projects.Project
  import Ecto.Changeset

  plug :authorize

  @doc """
  Lists all projects in the system with their owner info.
  """
  def index(conn, params) do
    page = String.to_integer(Map.get(params, "page", "1")) - 1
    filter = Map.get(params, "filter", nil)

    projects = list_all_projects(page, filter)
    project_owners = get_project_owners(projects.data)

    conn
    |> put_meta(:title, dgettext("admin", "Manage Projects"))
    |> assign(:projects, projects)
    |> assign(:project_owners, project_owners)
    |> render("index.html")
  end

  @doc """
  Show form to create a project for any user.
  """
  def new(conn, _params) do
    users = Auth.list_users()
    changeset = change(%Project{})

    conn
    |> put_meta(:title, dgettext("admin", "Create Project"))
    |> assign(:changeset, changeset)
    |> assign(:users, users)
    |> render("new.html")
  end

  @doc """
  Create a project for a specific user.
  """
  def create(conn, %{"project" => project_params}) do
    user_id = project_params["user_id"]

    case Projects.create_project(user_id, %{"name" => project_params["name"]}) do
      {:ok, _project} ->
        conn
        |> put_flash(:info, dgettext("admin", "Project created successfully"))
        |> redirect(to: Routes.project_admin_path(conn, :index))

      {:error, _changeset} ->
        users = Auth.list_users()
        changeset = change(%Project{}) |> add_error(:name, "Failed to create project")

        conn
        |> put_status(400)
        |> put_flash(:error, dgettext("admin", "Could not create project"))
        |> assign(:changeset, changeset)
        |> assign(:users, users)
        |> render("new.html")
    end
  end

  @doc """
  Edit project settings (name + data like EVO config).
  """
  def edit(conn, %{"id" => project_id}) do
    project = Projects.get_project(project_id)

    if project do
      changeset = change(project)
      owner = get_project_owner(project)

      conn
      |> put_meta(:title, dgettext("admin", "Edit Project: %{name}", name: project.name))
      |> assign(:project, project)
      |> assign(:changeset, changeset)
      |> assign(:owner, owner)
      |> render("edit.html")
    else
      conn |> put_status(404) |> halt()
    end
  end

  @doc """
  Update project settings.
  """
  def update(conn, %{"id" => project_id, "project" => project_params}) do
    project = Projects.get_project(project_id)

    # Merge data fields
    data = project.data || %{}

    new_data =
      data
      |> maybe_put(project_params, "evo_dns")
      |> maybe_put(project_params, "evo_secret_key")

    params = %{
      "name" => project_params["name"],
      "data" => new_data
    }

    case Projects.update_project(project_id, params) do
      {:ok, _project} ->
        conn
        |> put_flash(:info, dgettext("admin", "Project updated successfully"))
        |> redirect(to: Routes.project_admin_path(conn, :index))

      {:error, changeset} ->
        owner = get_project_owner(project)

        conn
        |> put_status(400)
        |> assign(:project, project)
        |> assign(:changeset, changeset)
        |> assign(:owner, owner)
        |> render("edit.html")
    end
  end

  # -- Private helpers --

  defp list_all_projects(page, filter) do
    import Ecto.Query

    query =
      from(p in Project,
        order_by: [desc: p.inserted_at]
      )

    query =
      if filter && filter != "" do
        from(p in query, where: ilike(p.name, ^"%#{filter}%"))
      else
        query
      end

    Keila.Pagination.paginate(query, page: page, page_size: 20)
  end

  defp get_project_owners(projects) do
    projects
    |> Enum.map(fn project ->
      owner = get_project_owner(project)
      {project.id, owner}
    end)
    |> Enum.into(%{})
  end

  defp get_project_owner(project) do
    import Ecto.Query

    # Find user through group membership
    case Repo.one(
           from(ug in Keila.Auth.UserGroup,
             join: u in Keila.Auth.User,
             on: u.id == ug.user_id,
             where: ug.group_id == ^project.group_id,
             select: u,
             limit: 1
           )
         ) do
      nil -> nil
      user -> user
    end
  end

  defp maybe_put(data, params, key) do
    case Map.get(params, key) do
      nil -> data
      val -> Map.put(data, key, val)
    end
  end

  defp authorize(conn, _) do
    case conn.assigns.is_admin? do
      true -> conn
      false -> conn |> put_status(404) |> halt()
    end
  end
end
