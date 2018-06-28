defmodule Bolt.Consumer.GuildDelete do
  @moduledoc "Handles the `GUILD_DELETE` event."

  alias Bolt.BotLog
  alias Nostrum.Struct.Guild

  @spec handle(Guild.t()) :: :ok
  def handle(guild) do
    BotLog.emit("📤 left guild `#{guild.name}` (`#{guild.id}`)")
  end
end
