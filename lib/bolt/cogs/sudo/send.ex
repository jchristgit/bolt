defmodule Bolt.Cogs.Sudo.Send do
  @moduledoc false

  alias Bolt.Converters
  alias Nostrum.Api

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, [channel_or_snowflake | content_list]) do
    channel_id =
      case Converters.to_channel(msg.guild_id, channel_or_snowflake) do
        {:ok, channel} -> channel.id
        {:error, _} -> channel_or_snowflake
      end

    response =
      case Api.create_message(channel_id, Enum.join(content_list, " ")) do
        {:ok, _msg} -> "👌 sent that message to channel `#{channel_id}`"
        {:error, _} -> "🚫 could not send the message, does the channel exist?"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "🚫 this command expects two arguments, channel and message content"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
