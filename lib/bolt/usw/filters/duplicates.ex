defmodule Bolt.USW.Filters.Duplicates do
  @moduledoc "Filters duplicated messages by multiple authors."

  @behaviour Bolt.USW.Filter

  alias Bolt.{MessageCache, USW}
  alias Nostrum.Cache.UserCache
  alias Nostrum.Struct.Snowflake
  require Logger

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
      |> Stream.filter(&(&1.content == msg.content))
      |> Enum.take(count)

    if length(relevant_messages) >= count do
      relevant_messages
      |> Stream.dedup_by(& &1.author_id)
      |> Enum.each(fn duplicated_message ->
        case UserCache.get(duplicated_message.author_id) do
          {:ok, user} ->
            USW.punish(
              msg.guild_id,
              user,
              "exceeding the duplicated message limit (`DUPLICATES` filter)"
            )

          {:error, reason} ->
            Logger.warn(fn ->
              "attempted applying USW punishment to #{duplicated_message.author_id}," <>
                " but the user was not found in the cache (error: #{reason})"
            end)
        end
      end)

      :action
    else
      :passthrough
    end
  end
end
