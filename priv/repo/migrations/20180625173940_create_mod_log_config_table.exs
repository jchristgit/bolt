defmodule Bolt.Repo.Migrations.CreateModLogConfigTable do
  use Ecto.Migration

  def change do
    execute(
      """
      CREATE TYPE modlog_event AS ENUM (
        'AUTOMOD', 'BOT_UPDATE', 'CONFIG_UPDATE',
        'INFRACTION_CREATE', 'INFRACTION_UPDATE', 'INFRACTION_EVENTS',

        'CHANNEL_CREATE', 'CHANNEL_UPDATE', 'CHANNEL_DELETE',
        'MESSAGE_EDIT', 'MESSAGE_DELETE',
        'GUILD_MEMBER_ADD', 'GUILD_MEMBER_UPDATE', 'GUILD_MEMBER_REMOVE',
        'GUILD_ROLE_CREATE', 'GUILD_ROLE_UPDATE', 'GUILD_ROLE_DELETE',
        'USER_UPDATE'
      );
      """,
      "DROP TYPE modlog_event;"
    )

    create table("modlogconfig", primary_key: false, comment: "Moderation log configuration") do
      add(:guild_id, :bigint, primary_key: true, comment: "The guild ID this row applies to")

      add(
        :event,
        :modlog_event,
        primary_key: true,
        null: false,
        comment: "The event that is configured by this row"
      )

      add(:channel_id, :bigint, null: false, comment: "The channel ID to log this event in")
    end
  end
end
