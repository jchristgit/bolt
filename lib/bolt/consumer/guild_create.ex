defmodule Bolt.Consumer.GuildCreate do
  @moduledoc "Handles the `GUILD_CREATE` event."

  alias Bolt.BotLog
  alias Nostrum.Struct.Guild

  @spec handle(Guild.t()) :: :ok
  def handle(guild) do
    BotLog.emit(
      "📥 joined guild `#{guild.name}` (`#{guild.id}`), seeing #{guild.member_count} members"
    )

    :ok = :prometheus_gauge.set(:bolt_guild_members, [guild.id], guild.member_count)
  end
end
