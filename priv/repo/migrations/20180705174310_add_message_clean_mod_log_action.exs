defmodule Bolt.Repo.Migrations.AddMessageCleanModLogEvent do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    execute("ALTER TYPE modlog_event ADD VALUE 'MESSAGE_CLEAN';")
  end
end
