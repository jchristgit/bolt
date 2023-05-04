defmodule Bolt.CrowPlugins.NostrumCache do
  @moduledoc "Export Discord cache metadata to Munin."
  @behaviour Crow.Plugin

  alias Nostrum.Cache.ChannelCache
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Cache.UserCache

  @doc false
  @impl true
  def name(_opts) do
    'nostrum_cache'
  end

  @doc false
  @impl true
  def config(_opts) do
    [
      'graph_title Nostrum cache contents',
      'graph_args -l 0',
      'graph_category bolt',
      'graph_vlabel items',
      'channels.label channels in cache',
      'channels.info Total number of channels held in the ChannelCache',
      'guilds.label guilds in cache',
      'guilds.info Total number of guilds held in the GuildCache',
      'members.label members in cache',
      'members.info Total number of members held in the GuildCache summed across guilds',
      'users.label users in cache',
      'users.info Total number of users held in the UserCache'
    ]
  end

  @doc false
  @impl true
  def values(_opts) do
    [
      'channels.value #{table_size(ChannelCache.ETS.tabname())}',
      'guilds.value #{table_size(GuildCache.ETS.tabname())}',
      'members.value #{Enum.sum(GuildCache.select_all(&Enum.count(&1.members)))}',
      'users.value #{table_size(UserCache.ETS.tabname())}'
    ]
  end

  defp table_size(name) do
    :ets.info(name, :size)
  end
end
