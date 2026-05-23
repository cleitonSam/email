defmodule Keila.Empresas do
  @moduledoc """
  Context do sistema multi-empresa.

  Cada empresa é um tenant: tem CNPJ, nome e um Projeto isolado. O admin
  master cadastra a empresa e o sistema dispara um convite por e-mail pro
  responsável. Ao aceitar o convite, a pessoa vira dona do projeto.
  """
  import Ecto.Query
  alias Keila.Repo
  alias Keila.Empresas.Empresa
  alias Keila.Projects
  alias Keila.Auth.Invitations

  @doc "Lista todas as empresas, mais recentes primeiro."
  def list_empresas do
    Empresa
    |> order_by([e], desc: e.inserted_at)
    |> preload(:project)
    |> Repo.all()
  end

  @doc "Busca uma empresa pelo id."
  def get_empresa(id), do: Repo.get(Empresa, id) |> Repo.preload(:project)

  @doc "Indica se um CNPJ (normalizado, só dígitos) já está cadastrado."
  def cnpj_em_uso?(cnpj) when is_binary(cnpj) do
    digits = String.replace(cnpj, ~r/[^0-9]/, "")
    Repo.exists?(from(e in Empresa, where: e.cnpj == ^digits))
  end

  def cnpj_em_uso?(_), do: false

  @doc """
  Cadastra uma nova empresa: cria o Projeto isolado, grava a Empresa e
  dispara o convite por e-mail pro responsável.

  `admin_user_id` é o usuário master que está cadastrando — ele fica como
  dono inicial do projeto até o responsável aceitar o convite.

  Retorna `{:ok, empresa}`, `{:ok, empresa, :email_failed}` ou
  `{:error, changeset}`.
  """
  def cadastrar_empresa(admin_user_id, params) do
    changeset = Empresa.creation_changeset(params)

    cond do
      not changeset.valid? ->
        {:error, %{changeset | action: :insert}}

      cnpj_em_uso?(Ecto.Changeset.get_field(changeset, :cnpj)) ->
        {:error,
         %{
           Ecto.Changeset.add_error(changeset, :cnpj, "CNPJ já cadastrado")
           | action: :insert
         }}

      true ->
        nome = Ecto.Changeset.get_field(changeset, :nome)

        resultado =
          Repo.transaction(fn ->
            with {:ok, project} <- Projects.create_project(admin_user_id, %{"name" => nome}),
                 {:ok, empresa} <-
                   changeset
                   |> Ecto.Changeset.put_change(:project_id, project.id)
                   |> Repo.insert() do
              empresa
            else
              {:error, error_changeset} -> Repo.rollback(error_changeset)
            end
          end)

        finalizar_cadastro(resultado, admin_user_id)
    end
  end

  defp finalizar_cadastro({:ok, empresa}, admin_user_id) do
    case enviar_convite(empresa, admin_user_id) do
      :ok -> {:ok, empresa}
      :error -> {:ok, empresa, :email_failed}
    end
  end

  defp finalizar_cadastro({:error, changeset}, _admin_user_id) do
    {:error, %{changeset | action: :insert}}
  end

  @doc "Reenvia o convite de acesso pro responsável da empresa."
  def reenviar_convite(%Empresa{} = empresa, admin_user_id) do
    enviar_convite(empresa, admin_user_id)
  end

  defp enviar_convite(%Empresa{} = empresa, admin_user_id) do
    params = %{
      email: empresa.email_responsavel,
      project_id: empresa.project_id,
      invited_by_user_id: admin_user_id,
      role: "owner"
    }

    case Invitations.create(params) do
      {:ok, _invitation} -> :ok
      {:ok, _invitation, :email_failed} -> :error
      {:error, _changeset} -> :error
    end
  end
end
