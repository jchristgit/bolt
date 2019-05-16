defmodule Bolt.Cogs.Graphs do
  @moduledoc false
  @behaviour Nosedrum.Command

  alias Bolt.Commander.Checks
  alias Bolt.Constants
  alias Bolt.CrowPlugins.GuildMembers, as: GuildMembersPlugin
  alias Bolt.CrowPlugins.GuildMessageCounts, as: GuildMessageCountsPlugin
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Guild

  # Known time scales.
  @time_scales ["day", "week", "month", "year"]

  @impl true
  def usage,
    do: [
      "graphs",
      "graphs members [day|week|month|year]",
      "graphs messages [day|week|month|year]"
    ]

  @impl true
  def description,
    do: """
    Bolt collects a bunch of anonymous statistics about your server and
    provides statistics that you can look into. The subcommands of this command
    display individual graph via the given timeframe. If no timeframe is given,
    the statistics over the past day are displayed.

    **Examples**
    ```rs
    // Display message count statistics over the past week.
    .graphs messages week

    // Display member count statistics over the past year.
    .graphs members year
    ```
    """

  @impl true
  def predicates, do: [&Checks.guild_only/1]

  @impl true
  def command(msg, ["members", scale]) when scale in @time_scales do
    embed = %Embed{
      title: "Guild member count by #{scale}",
      description: """
      This graph showcases the total amount of guild members on \
      this server over the past #{scale}.
      """,
      color: Constants.color_blue(),
      image: %Embed.Image{
        url: graph_link(GuildMembersPlugin.name(), msg.guild_id, scale)
      },
      footer: %Embed.Footer{
        text: "powered by munin & rrdtool",
        icon_url: "https://avatars0.githubusercontent.com/u/909917?s=200&v=4"
      }
    }

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
  end

  def command(msg, ["members"]), do: command(msg, ["members", "day"])

  def command(msg, ["messages", scale]) when scale in @time_scales do
    embed = %Embed{
      title: "Hourly messages by #{scale}",
      description: """
      This graph showcases the average messages sent per hour on \
      this server over the past #{scale}.
      """,
      color: Constants.color_blue(),
      image: %Embed.Image{
        url: graph_link(GuildMessageCountsPlugin.name(), msg.guild_id, scale)
      },
      footer: %Embed.Footer{
        text: "powered by munin & rrdtool",
        icon_url: "https://avatars0.githubusercontent.com/u/909917?s=200&v=4"
      }
    }

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
  end

  def command(msg, ["messages"]), do: command(msg, ["messages", "day"])

  def command(msg, _args) do
    response = """
    Bolt currently collects data for this server for the following data:

    - **Guild member count**, see `.graphs members [day|week|month|year]`.
    - **Message count**, see `.graphs messages [day|week|month|year]`.

    If you have more suggestions for graphs, feel free suggest them \
    on bolt's server!
    """

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  @spec graph_link(String.t(), Guild.id(), String.t()) :: String.t()
  defp graph_link(name, guild_id, scale) do
    "https://munin.#{Application.get_env(:bolt, :web_domain)}/munin/bolt/bolt" <>
      "/#{name}/gid_#{guild_id}-#{scale}.png"
  end
end
