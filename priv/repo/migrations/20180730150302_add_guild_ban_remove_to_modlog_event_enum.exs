defmodule Bolt.Repo.Migrations.AddGuildBanRemoveToModlogEventEnum do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    execute("ALTER TYPE modlog_event ADD VALUE 'GUILD_BAN_REMOVE';")
  end
end
