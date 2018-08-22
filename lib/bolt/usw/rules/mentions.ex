defmodule Bolt.USW.Rules.Mentions do
  @moduledoc "Filters out spam of user mentions."
  @behaviour Bolt.USW.Rule

  alias Bolt.{MessageCache, USW}
  alias Nostrum.Struct.Message

  @impl true
  @spec apply(Message.t(), non_neg_integer(), non_neg_integer(), Snowflake.t()) ::
          :action | :passthrough
  def apply(msg, limit, interval, interval_seconds_ago_snowflake) do
    recent_mentions =
      msg.guild_id
      |> MessageCache.recent_in_guild()
      |> Stream.filter(&(&1.id >= interval_seconds_ago_snowflake))
      |> Stream.filter(&(&1.author_id == msg.author.id))
      |> Stream.map(& &1.total_mentions)
      |> Enum.sum()

    if recent_mentions >= limit do
      USW.punish(
        msg.guild_id,
        msg.author,
        "sending #{recent_mentions} user mentions in #{interval}s"
      )

      :action
    else
      :passthrough
    end
  end
end
