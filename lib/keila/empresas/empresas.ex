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

  @doc "Busca a empresa vinculada a um projeto (nil se for um projeto comum)."
  def get_empresa_por_projeto(project_id) do
    Repo.get_by(Empresa, project_id: project_id)
  end

  @doc "Marca a empresa como ativa (convite aceito)."
  def ativar(%Empresa{} = empresa) do
    empresa
    |> Empresa.update_changeset(%{status: "ativa"})
    |> Repo.update()
  end

  @doc """
  Aprova o KYB de uma empresa (Master Admin). Libera o disparo de campanhas.
  `master_user_id` é quem aprovou — registrado na empresa.
  """
  def aprovar_kyb(%Empresa{} = empresa, master_user_id) do
    empresa
    |> Empresa.kyb_changeset(%{
      kyb_status: "aprovado",
      kyb_aprovado_em: DateTime.utc_now() |> DateTime.truncate(:second),
      kyb_aprovado_por_id: master_user_id,
      kyb_motivo_rejeicao: nil
    })
    |> Repo.update()
  end

  @doc "Rejeita o KYB de uma empresa, registrando o motivo. Mantém o envio bloqueado."
  def rejeitar_kyb(%Empresa{} = empresa, master_user_id, motivo) do
    empresa
    |> Empresa.kyb_changeset(%{
      kyb_status: "rejeitado",
      kyb_aprovado_em: nil,
      kyb_aprovado_por_id: master_user_id,
      kyb_motivo_rejeicao: motivo
    })
    |> Repo.update()
  end

  @doc "Bloqueia o envio de uma empresa (reputação/abuso)."
  def bloquear(%Empresa{} = empresa) do
    empresa
    |> Empresa.update_changeset(%{nome: empresa.nome, status: "bloqueada"})
    |> Repo.update()
  end

  @doc "Reativa uma empresa previamente bloqueada."
  def desbloquear(%Empresa{} = empresa) do
    empresa
    |> Empresa.update_changeset(%{nome: empresa.nome, status: "ativa"})
    |> Repo.update()
  end

  @doc "Atualiza dados gerais da empresa (dono ou master)."
  def atualizar(%Empresa{} = empresa, params) do
    empresa
    |> Empresa.update_changeset(params)
    |> Repo.update()
  end

  @doc """
  Indica se a empresa pode disparar campanhas: KYB aprovado e status operacional
  liberado (não bloqueada/cancelada). Regra inegociável nº 7 do Prompt Mestre.

  Projeto sem empresa vinculada (`nil`) NÃO é bloqueado aqui — preserva o
  comportamento legado de projetos comuns do Keila.
  """
  @spec pode_enviar?(Empresa.t() | nil) :: boolean()
  def pode_enviar?(nil), do: true

  def pode_enviar?(%Empresa{kyb_status: "aprovado", status: status})
      when status in ["convidada", "ativa"],
      do: true

  def pode_enviar?(%Empresa{}), do: false

  @doc """
  Mesmo que `pode_enviar?/1`, mas a partir de um `project_id`. Usado pelo worker
  de envio como gate por empresa.
  """
  @spec projeto_pode_enviar?(term()) :: boolean()
  def projeto_pode_enviar?(project_id) do
    project_id
    |> get_empresa_por_projeto()
    |> pode_enviar?()
  end

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
                   |> Ecto.Changeset.put_change(:criado_por_id, admin_user_id)
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
