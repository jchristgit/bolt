defmodule Bolt.USW.Rules.Duplicates do
  @moduledoc "Filters duplicated messages by multiple authors."
  @behaviour Bolt.USW.Rule

  alias Bolt.USW
  alias Nosedrum.MessageCache.Agent, as: MessageCache
  alias Nostrum.Struct.Snowflake
  require Logger

  @impl true
  @spec apply(Message.t(), non_neg_integer(), non_neg_integer(), Snowflake.t()) ::
          :action | :passthrough
  def apply(msg, limit, interval, interval_seconds_ago_snowflake) do
    relevant_messages =
      msg.guild_id
      |> MessageCache.recent_in_guild(:infinity, Bolt.MessageCache)
      |> Stream.filter(&(&1.id >= interval_seconds_ago_snowflake))
      |> Stream.filter(&(&1.content == msg.content))
      |> Enum.take(limit)

    recent_duplicates = length(relevant_messages)

    if recent_duplicates >= limit do
      reason = "sending #{recent_duplicates} duplicated messages in #{interval}s"

      relevant_messages
      |> Stream.dedup_by(& &1.author.id)
      |> Enum.each(&USW.punish(&1.guild_id, &1.author.id, reason))

      :action
    else
      :passthrough
    end
  end
end
