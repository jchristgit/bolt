defmodule Bolt.Consumer.GuildBanAdd do
  @moduledoc "Handles the `GUILD_BAN_ADD` event."

  alias Bolt.ModLog
  alias Nostrum.Struct.{Guild, User}

  @spec handle(Guild.id(), %{
          guild_id: Guild.id(),
          user: %{
            avatar: User.avatar(),
            discriminator: User.discriminator(),
            id: User.id(),
            username: User.username()
          }
        }) :: :noop | ModLog.on_emit()
  def handle(guild_id, %{user: user}) do
    ModLog.emit(
      guild_id,
      "GUILD_BAN_ADD",
      "#{user.username}##{user.discriminator} (`#{user.id}`) was banned"
    )
  end
end
