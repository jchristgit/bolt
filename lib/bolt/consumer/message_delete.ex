defmodule Bolt.Consumer.MessageDelete do
  @moduledoc "Handles the `MESSAGE_DELETE` event."

  alias Bolt.{Constants, Helpers, MessageCache, ModLog}
  alias Nostrum.Struct.{Channel, Embed, Guild, Message, Snowflake}

  @spec handle(Channel.id(), Guild.id(), Message.id()) :: {:ok, Message.t()}
  def handle(channel_id, guild_id, msg_id) do
    content =
      case MessageCache.get(channel_id, msg_id) do
        nil -> "*unknown, message not in cache*"
        cached_msg -> String.slice(cached_msg.content, 0..1020)
      end

    embed = %Embed{
      color: Constants.color_red(),
      fields: [
        %Embed.Field{
          name: "Metadata",
          value: """
          Channel: <##{channel_id}>
          Creation: #{msg_id |> Snowflake.creation_time() |> Helpers.datetime_to_human()}
          Message ID: #{msg_id}
          """,
          inline: true
        },
        %Embed.Field{
          name: "Content",
          value: content,
          inline: true
        }
      ]
    }

    ModLog.emit(
      guild_id,
      "MESSAGE_DELETE",
      embed
    )
  end
end
