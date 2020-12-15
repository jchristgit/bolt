defmodule Bolt.USW.Rules.Burst do
  @moduledoc "Filters messages sent in quick succession."
  @behaviour Bolt.USW.Rule

  alias Bolt.USW
  alias Nosedrum.MessageCache.Agent, as: MessageCache
  alias Nostrum.Struct.{Message, Snowflake}

  @impl true
  @spec apply(Message.t(), non_neg_integer(), non_neg_integer(), Snowflake.t()) ::
          :action | :passthrough
  def apply(msg, limit, interval, interval_seconds_ago_snowflake) do
    total_recents =
      msg.guild_id
      |> MessageCache.recent_in_guild(:infinity, Bolt.MessageCache)
      |> Stream.filter(&(&1.id >= interval_seconds_ago_snowflake))
      |> Stream.filter(&(&1.author.id == msg.author.id))
      |> Enum.take(limit)
      |> length()

    if total_recents >= limit do
      USW.punish(
        msg.guild_id,
        msg.author,
        "sending #{total_recents} messages in #{interval}s"
      )

      :action
    else
      :passthrough
    end
  end
end
