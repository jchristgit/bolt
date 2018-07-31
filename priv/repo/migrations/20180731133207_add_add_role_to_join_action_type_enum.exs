defmodule Bolt.Repo.Migrations.AddAddRoleToJoinActionTypeEnum do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    execute("ALTER TYPE join_action_type ADD VALUE 'add_role';")
  end
end
