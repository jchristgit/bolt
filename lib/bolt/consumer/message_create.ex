defmodule Bolt.Consumer.MessageCreate do
  @moduledoc "Handles the `MESSAGE_CREATE` gateway event."

  @nosedrum_storage_implementation Nosedrum.Storage.ETS

  alias Bolt.CrowPlugins.GuildMessageCounts
  alias Bolt.{MessageCache, USW}
  alias Nosedrum.Invoker.Split, as: CommandInvoker
  alias Nostrum.Struct.Message

  @spec handle(Message.t()) :: :ok | nil
  def handle(msg) do
    unless msg.author.bot do
      CommandInvoker.handle_message(msg, @nosedrum_storage_implementation)
      MessageCache.consume(msg)
      USW.apply(msg)
      GuildMessageCounts.record_message(msg)
    end
  end
end
