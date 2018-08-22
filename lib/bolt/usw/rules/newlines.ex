defmodule Bolt.USW.Rules.Newlines do
  @moduledoc "Filters out spam of newlines."
  @behaviour Bolt.USW.Rule

  alias Bolt.{MessageCache, USW}
  alias Nostrum.Struct.Message

  @newline_re ~r|\n|

  @impl true
  @spec apply(Message.t(), non_neg_integer(), non_neg_integer(), Snowflake.t()) ::
          :action | :passthrough
  def apply(msg, limit, interval, interval_seconds_ago_snowflake) do
    recent_newlines =
      msg.guild_id
      |> MessageCache.recent_in_guild()
      |> Stream.filter(&(&1.id >= interval_seconds_ago_snowflake))
      |> Stream.filter(&(&1.author_id == msg.author.id))
      |> Stream.map(& &1.content)
      |> Stream.map(&Regex.scan(@newline_re, &1))
      |> Stream.map(&Enum.count(&1))
      |> Enum.sum()

    if recent_newlines >= limit do
      USW.punish(
        msg.guild_id,
        msg.author,
        "sending #{recent_newlines} newlines in #{interval}s"
      )

      :action
    else
      :passthrough
    end
  end
end
