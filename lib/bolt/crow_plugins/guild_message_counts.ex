defmodule Bolt.CrowPlugins.GuildMessageCounts do
  @moduledoc """
  A multigraph plugin that displays the total amount of messages sent
  on guilds visible through Bolt.
  """
  # credo:disable-for-this-file Credo.Check.Refactor.PipeChainStart

  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Message

  @behaviour Crow.Plugin

  @table :bolt_message_counts_by_guild

  @spec table_name :: atom()
  def table_name, do: @table

  @spec record_message(Message.t()) :: :ok
  def record_message(%Message{guild_id: nil}), do: :ok

  def record_message(%Message{guild_id: guild_id}) do
    :ets.update_counter(@table, guild_id, 1, {guild_id, 0})
  end

  @doc false
  @impl true
  def name do
    'guild_message_counts'
  end

  @doc false
  @impl true
  def config do
    [
      'multigraph guild_message_counts',
      'graph_title messages per hour across all guilds',
      'graph_vlabel messages per hour',
      'graph_args -l 0',
      'graph_category discord',
      'graph_period hour',
      'graph_scale no',
      'graph_info messages per hour in all guilds bolt can see',
      'messages.label messages',
      'messages.min 0',
      'messages.type DERIVE'
    ] ++ config_for_guilds()
  end

  @doc false
  @impl true
  def values do
    total_message_count =
      @table
      |> :ets.select([{{:"$1", :"$2"}, [], [:"$2"]}])
      |> Enum.sum()

    [
      'multigraph guild_message_counts',
      'messages.value #{total_message_count}'
    ] ++ values_for_guilds()
  end

  defp config_for_guilds do
    @table
    |> :ets.select([{{:"$1", :"$2"}, [], [:"$1"]}])
    |> Enum.map(fn guild_id ->
      name = get_guild_name(guild_id)

      [
        'multigraph guild_message_counts.gid_#{guild_id}',
        'graph_title message counts for #{name}',
        'graph_vlabel messages per hour',
        'graph_period hour',
        'graph_args -l 0',
        'graph_scale no',
        'graph_category discord',
        'graph_info messages sent per hour for guild #{name} (#{guild_id})',
        'messages.label messages',
        'messages.min 0',
        'messages.type DERIVE'
      ]
    end)
    |> :lists.concat()
  end

  defp values_for_guilds do
    @table
    |> :ets.tab2list()
    |> Enum.map(fn {id, message_count} ->
      ['multigraph guild_message_counts.gid_#{id}', 'messages.value #{message_count}']
    end)
    |> :lists.concat()
  end

  @spec get_guild_name(Guild.id()) :: String.t()
  defp get_guild_name(guild_id) do
    case GuildCache.select(guild_id, & &1.name) do
      {:ok, name} -> name
      {:error, _why} -> "#{guild_id}"
    end
  end
end
