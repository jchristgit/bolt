defmodule Bolt.USW.Filters.Burst do
  @moduledoc "Filters messages sent in quick succession."
  @behaviour Bolt.USW.Filter

  alias Bolt.{MessageCache, USW}
  alias Nostrum.Struct.{Message, Snowflake}

  @impl true
  @spec apply(Message.t(), non_neg_integer(), non_neg_integer()) :: :action | :passthrough
  def apply(msg, count, interval) do
    interval_seconds_ago_snowflake =
      DateTime.utc_now()
      |> DateTime.to_unix()
      |> Kernel.-(interval)
      |> DateTime.from_unix!()
      |> Snowflake.from_datetime!()

    relevant_messages =
      msg.guild_id
      |> MessageCache.recent_in_guild()
      |> Stream.filter(&(&1.id >= interval_seconds_ago_snowflake))
      |> Stream.filter(&(&1.author_id == msg.author.id))
      |> Enum.take(count)

    if length(relevant_messages) >= count do
      USW.punish(
        msg.guild_id,
        msg.author,
        "exceeding the message limit (`BURST` filter)"
      )

      :action
    else
      :passthrough
    end
  end
end
