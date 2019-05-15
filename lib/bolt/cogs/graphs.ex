defmodule Bolt.Cogs.Graphs do
  @moduledoc false
  @behaviour Nosedrum.Command

  alias Bolt.Commander.Checks
  alias Bolt.CrowPlugins.GuildMembers, as: GuildMembersPlugin
  alias Bolt.CrowPlugins.GuildMessageCounts, as: GuildMessageCountsPlugin
  alias Nostrum.Api
  alias Nostrum.Struct.Guild

  # The base URL at which the Munin graphs live.
  @munin_base_url "https://munin.#{Application.get_env(:bolt, :web_domain)}/munin/bolt/bolt"

  @impl true
  def usage, do: ["graphs"]

  @impl true
  def description,
    do: """
    Bolt collects a bunch of anonymous statistics about your server and
    provides statistics that you can look into. This command links to
    the graphs for this server.
    """

  @impl true
  def predicates, do: [&Checks.guild_only/1]

  @impl true
  def command(msg, _args) do
    response = """
    Bolt currently provides data for this server for the following data:

    **Guild member count**: #{guild_members_url(msg.guild_id)}
    This counts the total amount of users on your server.

    **Message count**: #{guild_message_counts_url(msg.guild_id)}
    This graph samples message counts every 5 minutes giving you a good \
    indication of activity on your server.

    For accessing the site, you can use the username `public` with password `public`.

    If you have more suggestions for graphs, feel free suggest them \
    on bolt's server!
    """

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  @spec guild_members_url(Guild.id()) :: String.t()
  defp guild_members_url(guild_id),
    do: @munin_base_url <> "/#{GuildMembersPlugin.name()}/gid_#{guild_id}.html"

  @spec guild_message_counts_url(Guild.id()) :: String.t()
  defp guild_message_counts_url(guild_id),
    do: @munin_base_url <> "/#{GuildMessageCountsPlugin.name()}/gid_#{guild_id}.html"
end
