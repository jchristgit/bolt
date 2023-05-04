defmodule Bolt.USW.Rules.Mentions do
  @moduledoc "Filters out spam of user mentions."
  @behaviour Bolt.USW.Rule

  alias Bolt.USW
  alias Nosedrum.MessageCache.Agent, as: MessageCache
  alias Nostrum.Struct.Message

  @impl true
  @spec apply(Message.t(), non_neg_integer(), non_neg_integer(), Snowflake.t()) ::
          :action | :passthrough
  def apply(msg, limit, interval, interval_seconds_ago_snowflake) do
    recent_mentions =
      msg.guild_id
      |> MessageCache.recent_in_guild(:infinity, Bolt.MessageCache)
      |> Stream.filter(&(&1.id >= interval_seconds_ago_snowflake))
      |> Stream.filter(&(&1.author.id == msg.author.id))
      |> Stream.map(&length(&1.mentions))
      |> Enum.sum()

    if recent_mentions >= limit do
      USW.punish(
        msg.guild_id,
        msg.author.id,
        "sending #{recent_mentions} user mentions in #{interval}s"
      )

      :action
    else
      :passthrough
    end
  end
end
