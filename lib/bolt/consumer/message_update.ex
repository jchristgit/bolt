defmodule Bolt.Consumer.MessageUpdate do
  @moduledoc "Handles the `MESSAGE_UPDATE` event."

  alias Bolt.{Constants, Helpers, MessageCache, ModLog}
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.{Author, Field}
  alias Nostrum.Struct.Snowflake

  @spec handle(Nostrum.Struct.Message.t()) :: :ok
  def handle(msg) do
    unless Map.get(msg, :content, "") == "" do
      from_cache = MessageCache.get(msg.guild_id, msg.id)

      embed = %Embed{
        author: %Author{
          name: "#{msg.author.username}##{msg.author.discriminator} (#{msg.author.id})"
          # Once the nostrum bug with users being sent as raw maps
          # in the event payload is fixed, edit this back in, and change
          # the user#discrim building above to User.full_name/1.
          # icon_url: User.avatar_url(author)
        },
        color: Constants.color_blue(),
        url: "https://discordapp.com/channels/#{msg.guild_id}/#{msg.channel_id}/#{msg.id}",
        fields: [
          %Field{
            name: "Metadata",
            value: """
            Channel: <##{msg.channel_id}>
            Creation: #{msg.id |> Snowflake.creation_time() |> Helpers.datetime_to_human()}
            Message ID: #{msg.id}
            """
          },
          %Field{
            name: "Old content",
            value:
              (fn ->
                 content =
                   if(from_cache != nil, do: from_cache.content, else: "*unknown, not in cache*")

                 String.slice(content, 0..1020)
               end).(),
            inline: true
          },
          %Field{
            name: "Updated content",
            value: String.slice(msg.content, 0..1020),
            inline: true
          }
        ]
      }

      ModLog.emit_embed(msg.guild_id, "MESSAGE_EDIT", embed)

      MessageCache.update(msg)
    end
  end
end
