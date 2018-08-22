defmodule Bolt.USW.Rules.Duplicates do
  @moduledoc "Filters duplicated messages by multiple authors."
  @behaviour Bolt.USW.Rule

  alias Bolt.{MessageCache, USW}
  alias Nostrum.Cache.UserCache
  alias Nostrum.Struct.Snowflake
  require Logger

  @impl true
  @spec apply(Message.t(), non_neg_integer(), non_neg_integer(), Snowflake.t()) ::
          :action | :passthrough
  def apply(msg, limit, interval, interval_seconds_ago_snowflake) do
    relevant_messages =
      msg.guild_id
      |> MessageCache.recent_in_guild()
      |> Stream.filter(&(&1.id >= interval_seconds_ago_snowflake))
      |> Stream.filter(&(&1.content == msg.content))
      |> Enum.take(limit)

    recent_duplicates = length(relevant_messages)

    if recent_duplicates >= limit do
      relevant_messages
      |> Stream.dedup_by(& &1.author_id)
      |> Enum.each(fn duplicated_message ->
        case UserCache.get(duplicated_message.author_id) do
          {:ok, user} ->
            USW.punish(
              msg.guild_id,
              user,
              "sending #{recent_duplicates} duplicated messages in #{interval}s"
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
