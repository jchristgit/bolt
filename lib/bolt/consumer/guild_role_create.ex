defmodule Bolt.Consumer.GuildRoleCreate do
  @moduledoc "Handles the `GUILD_ROLE_CREATE` event."

  alias Bolt.{Helpers, ModLog}
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Role

  @spec handle(Guild.id(), Role.t()) :: ModLog.on_emit()
  def handle(guild_id, created_role) do
    ModLog.emit(
      guild_id,
      "GUILD_ROLE_CREATE",
      Helpers.clean_content(
        "role #{Helpers.clean_content(created_role.name)} (`#{created_role.id}`) was created"
      )
    )
  end
end
