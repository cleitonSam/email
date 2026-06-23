defmodule Keila.Rbac do
  @moduledoc """
  Controle de acesso por papel dentro de um projeto/empresa
  (perfis Dono/Operador/Visualizador/Compliance — seção 2 do Prompt Mestre).

  Reaproveita a infraestrutura de papéis/permissões do Keila
  (`Keila.Auth.has_permission?/3`), escopada no grupo do projeto.

  ## Compatibilidade (não-quebra)

  `can?/3` aplica um default permissivo: se o usuário **não tem nenhum papel de
  empresa** atribuído naquele projeto, é tratado como dono (acesso total). Isso
  preserva os projetos/usuários que já existiam antes do RBAC. A restrição só
  passa a valer para usuários que receberam um papel explícito (ex.: via convite).
  """
  import Ecto.Query

  alias Keila.Repo
  alias Keila.Auth
  alias Keila.Auth.{Role, UserGroupRole}

  @doc """
  Indica se o usuário pode executar a ação que exige `permission` no projeto.

  Aceita um `%Project{}` (ou qualquer struct/map com `:group_id`).
  """
  @spec can?(integer(), map(), String.t()) :: boolean()
  def can?(user_id, %{group_id: group_id}, permission)
      when is_integer(group_id) or is_binary(group_id) do
    if has_company_role?(user_id, group_id) do
      Auth.has_permission?(user_id, group_id, permission)
    else
      true
    end
  end

  def can?(_user_id, _project, _permission), do: false

  @doc "Lista os nomes dos papéis de empresa que o usuário tem no grupo."
  @spec roles_in_group(integer(), integer()) :: [String.t()]
  def roles_in_group(user_id, group_id) do
    company_roles_query(user_id, group_id)
    |> select([_ugr, _ug, r], r.name)
    |> Repo.all()
  end

  @doc "Indica se o usuário tem algum papel de empresa atribuído no grupo."
  @spec has_company_role?(integer(), integer()) :: boolean()
  def has_company_role?(user_id, group_id) do
    company_roles_query(user_id, group_id)
    |> Repo.exists?()
  end

  defp company_roles_query(user_id, group_id) do
    role_names = Auth.company_role_names()

    from(ugr in UserGroupRole,
      join: ug in assoc(ugr, :user_group),
      join: r in Role,
      on: r.id == ugr.role_id,
      where: ug.user_id == ^user_id and ug.group_id == ^group_id,
      where: r.name in ^role_names
    )
  end
end
