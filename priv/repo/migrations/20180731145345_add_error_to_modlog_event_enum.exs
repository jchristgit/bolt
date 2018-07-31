defmodule Bolt.Repo.Migrations.AddErrorToModlogEventEnum do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    execute("ALTER TYPE modlog_event ADD VALUE 'ERROR';")
  end
end
