defmodule Bolt.Repo.Migrations.AddGuildBanAddToModlogEventEnum do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    execute("ALTER TYPE modlog_event ADD VALUE 'GUILD_BAN_ADD';")
  end
end
