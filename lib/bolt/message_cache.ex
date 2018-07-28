defmodule Bolt.MessageCache do
  @moduledoc "Caches the most recent x messages sent in channels for moderation."
  @max_messages_per_guild 200

  alias Nostrum.Struct.{Channel, Message, User}
  use Agent

  @typep cache_message :: %{
           author_id: User.id(),
           channel_id: Channel.id(),
           content: String.t(),
           total_mentions: non_neg_integer(),
           id: Message.id()
         }

  @spec start_link(GenServer.options()) :: Agent.on_start()
  def start_link(options) do
    Agent.start_link(fn -> %{} end, options)
  end

  @spec get(Guild.id(), Message.id()) :: cache_message | nil
  def get(guild_id, message_id) do
    case recent_in_guild(guild_id) do
      nil -> nil
      messages -> Enum.find(messages, &(&1.id == message_id))
    end
  end

  @spec recent_in_guild(Guild.id()) :: [cache_message] | nil
  def recent_in_guild(guild_id) do
    Agent.get(
      __MODULE__,
      fn state -> Map.get(state, guild_id) end
    )
  end

  @spec update(Message.t()) :: :ok
  def update(msg) do
    Agent.get_and_update(
      __MODULE__,
      fn state ->
        with guild_msgs when guild_msgs != nil <- Map.get(state, msg.guild_id),
             cached_idx when cached_idx != nil <- Enum.find_index(guild_msgs, &(&1.id == msg.id)) do
          {state,
           %{
             state
             | msg.guild_id =>
                 List.update_at(guild_msgs, cached_idx, &%{&1 | content: msg.content})
           }}
        else
          _err -> {state, state}
        end
      end
    )
  end

  @spec update_state(Message.t(), cache_message, cache_message) :: %{
          Guild.id() => [cache_message]
        }
  defp update_state(msg, msg_map, new_message_map) do
    Map.update(
      msg_map,
      msg.guild_id,
      [new_message_map],
      fn messages ->
        if length(messages) >= @max_messages_per_guild do
          [new_message_map | Enum.drop(messages, -1)]
        else
          [new_message_map | messages]
        end
      end
    )
  end

  @spec consume(Message.t()) :: [Message.t()]
  def consume(msg) do
    Agent.get_and_update(
      __MODULE__,
      fn msg_map ->
        new_message_map = %{
          author_id: msg.author.id,
          channel_id: msg.channel_id,
          content: msg.content,
          total_mentions: length(msg.mentions),
          id: msg.id
        }

        updated_map = update_state(msg, msg_map, new_message_map)
        {msg_map, updated_map}
      end
    )
  end
end
