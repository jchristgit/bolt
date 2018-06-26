defmodule Bolt.USW.Tracker do
  @moduledoc "Tracks a few last messages per channel / member for automatic moderation."
  @max_messages_per_user 5

  use Agent

  @spec start_link(GenServer.options()) :: Agent.on_start()
  def start_link(options) do
    Agent.start_link(fn -> %{} end, options)
  end

  @spec consume(Nostrum.Struct.Message.t()) :: [Nostrum.Struct.Message.t()]
  def consume(msg) do
    Agent.get_and_update(
      __MODULE__,
      fn msg_map ->
        new_message_map = %{
          channel_id: msg.channel_id,
          content: msg.content,
          guild_id: msg.channel_id,
          id: msg.id
        }

        updated_map =
          msg_map
          |> Map.update(
            msg.author.id,
            [new_message_map],
            fn messages ->
              if length(messages) >= @max_messages_per_user do
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
