defmodule Bolt.Repo.Migrations.AddDeleteInvocationToAcceptActionTypeEnum do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    execute("ALTER TYPE accept_action_type ADD VALUE 'delete_invocation';")
  end
end
