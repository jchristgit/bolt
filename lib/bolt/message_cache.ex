defmodule Bolt.MessageCache do
  @moduledoc "Caches the most recent x messages sent in channels for moderation."
  @max_messages_per_channel 50
  @typep cache_message :: %{
           author_id: Nostrum.Struct.User.id(),
           content: String.t(),
           id: Nostrum.Struct.Message.id()
         }

  use Agent

  @spec start_link(GenServer.options()) :: Agent.on_start()
  def start_link(options) do
    Agent.start_link(fn -> %{} end, options)
  end

  @spec recent_in_channel(Nostrum.Struct.Snowflake.t()) :: [cache_message] | nil
  def recent_in_channel(channel_id) do
    Agent.get(
      __MODULE__,
      fn state -> Map.get(state, channel_id) end
    )
  end

  @spec consume(Nostrum.Struct.Message.t()) :: [Nostrum.Struct.Message.t()]
  def consume(msg) do
    Agent.get_and_update(
      __MODULE__,
      fn msg_map ->
        new_message_map = %{
          author_id: msg.author.id,
          content: msg.content,
          id: msg.id
        }

        updated_map =
          msg_map
          |> Map.update(
            msg.channel_id,
            [new_message_map],
            fn messages ->
              if length(messages) >= @max_messages_per_channel do
                [new_message_map | Enum.drop(messages, -1)]
              else
                [new_message_map | messages]
              end
            end
          )

        {msg_map, updated_map}
      end
    )
  end
end
