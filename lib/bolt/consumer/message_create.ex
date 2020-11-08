defmodule Bolt.Consumer.MessageCreate do
  @moduledoc "Handles the `MESSAGE_CREATE` gateway event."

  @nosedrum_storage_implementation Nosedrum.Storage.ETS

  alias Bolt.{MessageCache, USW}
  alias Nosedrum.Invoker.Split, as: CommandInvoker
  alias Nostrum.Api
  alias Nostrum.Struct.Message

  @spec handle(Message.t()) :: :ok | nil
  def handle(msg) do
    unless msg.author.bot do
      case CommandInvoker.handle_message(msg, @nosedrum_storage_implementation) do
        {:error, {:unknown_subcommand, name, :known, known}} ->
          Api.create_message(
            msg.channel_id,
            "🚫 unknown subcommand, known subcommands: `#{Enum.join(known, "`, `")}`"
          )

        {:error, :predicate, {:error, reason}} ->
          Api.create_message(msg.channel_id, "❌ cannot evaluate permissions: #{reason}")

        _ ->
          :ok
      end

      MessageCache.consume(msg)
      USW.apply(msg)

      if msg.guild_id != nil do
        :ok =
          :prometheus_counter.inc(
            :bolt_guild_messages_total,
            [msg.guild_id, msg.channel_id]
          )
      end
    end
  end
end
