defmodule Bolt.Consumer.GuildBanAdd do
  @moduledoc "Handles the `GUILD_BAN_ADD` event."

  alias Bolt.Consumer.MessageDelete
  alias Bolt.ModLog
  alias Nosedrum.MessageCache.Agent, as: MessageCache
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
    {:ok, recents} = MessageCache.recent_in_guild(guild_id, :infinity, Bolt.MessageCache)

    recents
    |> Stream.filter(&(&1.author.id == user.id))
    |> Enum.each(&MessageDelete.log/1)

    ModLog.emit(
      guild_id,
      "GUILD_BAN_ADD",
      "#{user.username}##{user.discriminator} (`#{user.id}`) was banned"
    )
  end
end
