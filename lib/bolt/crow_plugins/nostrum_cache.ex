defmodule Bolt.CrowPlugins.NostrumCache do
  @moduledoc "Export Discord cache metadata to Munin."
  @behaviour Crow.Plugin

  alias Nostrum.Cache.GuildCache

  @doc false
  @impl true
  def name do
    'nostrum_cache'
  end

  @doc false
  @impl true
  def config do
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
  def values do
    [
      'channels.value #{:ets.info(:channels)[:size]}',
      'guilds.value #{Enum.count(GuildCache.all())}',
      'members.value #{Enum.sum(GuildCache.select_all(&Enum.count(&1.members)))}',
      'users.value #{:ets.info(:users)[:size]}'
    ]
  end
end
