defmodule Bolt.Consumer.GuildMemberRemove do
  @moduledoc "Handles the `GUILD_MEMBER_REMOVE` event."

  alias Bolt.ModLog
  alias Nostrum.Struct.{Guild, Message, User}

  @spec handle(Guild.id(), Guild.Member.t()) :: {:ok, Message.t()}
  def handle(guild_id, member) do
    ModLog.emit(
      guild_id,
      "GUILD_MEMBER_REMOVE",
      "#{User.full_name(member.user)} (`#{member.user.id}`) has left"
    )
  end
end
