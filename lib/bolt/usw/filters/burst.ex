defmodule Bolt.USW.Filters.Burst do
  @moduledoc "Filters messages sent in quick succession."
  @behaviour Bolt.USW.Filter

  alias Bolt.MessageCache
  alias Nostrum.Struct.Snowflake
  use Timex

  ## Filter implementation
  @spec apply(Nostrum.Struct.Message.t(), non_neg_integer(), non_neg_integer()) ::
          :action | :passthrough
  def apply(msg, count, interval) do
    recent_messages = MessageCache.recent_in_channel(msg.channel_id)
    by_user = Enum.filter(recent_messages, &(&1.author_id == msg.author.id))

    case by_user do
      # First message sent by user since last cache reap
      [_msg] ->
        :passthrough

      messages ->
        interval_seconds_ago = Timex.shift(DateTime.utc_now(), seconds: -interval)

        during_interval =
          messages
          |> Enum.filter(&Timex.after?(Snowflake.creation_time(&1.id), interval_seconds_ago))

        if length(during_interval) >= count do
          IO.puts("beep bop user exceeded limit")
          :action
        else
          :passthrough
        end
    end
  end
end
