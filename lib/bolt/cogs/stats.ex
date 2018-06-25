defmodule Bolt.Cogs.Stats do
  @moduledoc false

  alias Bolt.Constants
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Cache.Me
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Field
  alias Nostrum.Struct.Embed.Thumbnail
  alias Nostrum.Struct.User

  def command(msg, []) do
    total_guilds = GuildCache.all() |> Enum.count()
    guild_member_counts = GuildCache.select_all(fn guild -> guild.member_count end)

    response = %Embed{
      title: "Statistics",
      color: Constants.color_blue(),
      fields: [
        %Field{
          name: "Guilds",
          value: """
          **Total**: #{total_guilds}
          **Avg. members**: #{div(Enum.sum(guild_member_counts), total_guilds)}
          """,
          inline: true
        }
      ],
      thumbnail: %Thumbnail{
        url: User.avatar_url(Me.get())
      }
    }

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end

  def command(msg, _unknown_args) do
    response = "🚫 this command takes no arguments"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
