defmodule Bolt.Cogs.Stats do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Constants
  alias Nostrum.Api
  alias Nostrum.Cache.{GuildCache, Me}
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.{Field, Thumbnail}
  alias Nostrum.Struct.User

  @impl true
  def usage, do: ["stats"]

  @impl true
  def description, do: "Show general statistics about the bot."

  @impl true
  def predicates, do: []

  @impl true
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
    response = "ℹ️ usage: `stats`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
