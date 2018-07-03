defmodule Bolt.Consumer.GuildRoleCreate do
  @moduledoc "Handles the `GUILD_ROLE_CREATE` event."

  alias Bolt.ModLog
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Role

  @spec handle(Guild.id(), Role.t()) :: ModLog.on_emit() | :noop
  def handle(guild_id, created_role) do
    ModLog.emit(
      guild_id,
      "GUILD_ROLE_CREATE",
      "role #{created_role.name} (`#{created_role.id}`) was created"
    )
  end
end
