defmodule Bolt.Consumer.ChannelDelete do
  @moduledoc "Handles the `CHANNEL_DELETE` event."

  alias Bolt.ModLog
  alias Nostrum.Struct.Channel

  @spec handle(Channel.t()) :: nil | ModLog.on_emit()
  def handle(channel) do
    unless channel.guild_id == nil do
      type_name =
        case channel.type do
          0 -> "text channel"
          2 -> "voice channel"
          4 -> "category"
          _ -> "unknown channel type"
        end

      ModLog.emit(
        channel.guild_id,
        "CHANNEL_DELETE",
        "#{type_name} #{channel.name} (`#{channel.id}`) was deleted"
      )
    end
  end
end
