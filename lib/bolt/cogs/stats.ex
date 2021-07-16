defmodule Bolt.Cogs.Stats do
  @moduledoc false

  @behaviour Nosedrum.Command

  alias Bolt.Constants
  alias Nostrum.Api
  alias Nostrum.Cache.{GuildCache, Me}
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.{Field, Footer, Image, Thumbnail}
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
          Total: #{total_guilds}
          Users: #{Enum.sum(guild_member_counts)}
          """,
          inline: true
        },
        %Field{
          name: "System",
          value: """
          Running on Elixir #{System.version()}
          Metrics in [Munin](https://munin.jchri.st/spock/bolt/)
          """,
          inline: true
        }
      ],
      image: %Image{
        url:
          "https://munin.jchri.st/spock/bolt/nostrum_cache-month.png?_v=#{System.unique_integer()}"
      },
      footer: %Footer{
        text: "the graph above shows the discord objects seen by bolt, see munin for more"
      },
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
