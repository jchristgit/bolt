defmodule Bolt.Repo.Migrations.RenameAutomodEventForRoleAssignment do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    execute("ALTER TYPE modlog_event ADD VALUE 'SELF_ASSIGNABLE_ROLES'")
    execute("INSERT INTO modlogconfig (guild_id, event, channel_id) SELECT guild_id, 'SELF_ASSIGNABLE_ROLES', channel_id FROM modlogconfig WHERE event = 'AUTOMOD';")
  end
end
