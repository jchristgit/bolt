defmodule Bolt.Repo.Migrations.AddUniqueConstraintsToJoinActions do
  use Ecto.Migration

  def change do
    # Adding the same role multiple times does not make sense
    create(
      unique_index(
        "join_action",
        [:guild_id, "(data->'role_id')"],
        where: "action = 'add_role'"
      )
    )

    # There may only be one `send_dm` per guild
    create(
      unique_index(
        "join_action",
        [:guild_id, :action],
        name: "join_action_send_dm_unique_for_guild",
        where: "action = 'send_dm'"
      )
    )

    # There may only be one `send_guild` per guild per channel
    create(
      unique_index(
        "join_action",
        [:guild_id, "(data->'channel_id')"],
        name: "join_action_send_guild_unique_for_guild_and_channel",
        where: "action = 'send_guild'"
      )
    )
  end
end
