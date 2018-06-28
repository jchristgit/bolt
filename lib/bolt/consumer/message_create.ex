defmodule Bolt.Consumer.MessageCreate do
  @moduledoc "Handles the `MESSAGE_CREATE` gateway event."

  alias Bolt.{Commander, MessageCache, USW}
  alias Nostrum.Struct.Message

  @spec handle(Message.t()) :: :ok | nil
  def handle(msg) do
    unless msg.author.bot do
      Commander.handle_message(msg)
      MessageCache.consume(msg)
      USW.apply(msg)
    end
  end
end
