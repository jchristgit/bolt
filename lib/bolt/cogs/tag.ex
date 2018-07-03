defmodule Bolt.Cogs.Tag do
  @moduledoc false

  alias Nostrum.Api
  alias Nostrum.Struct.Message

  @spec command(Message.t(), [String.t()]) :: {:ok, Message.t()} | reference()
  def command(msg, ["create" | args]) do
    alias Bolt.Cogs.Tag.Create

    Create.command(msg, args)
  end

  def command(msg, ["delete" | args]) do
    alias Bolt.Cogs.Tag.Delete

    Delete.command(msg, args)
  end

  def command(msg, ["list" | args]) do
    alias Bolt.Cogs.Tag.List

    List.command(msg, args)
  end

  def command(msg, []) do
    response = "🚫 at least one argument (subcommand or tag to look up) is required"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, args) do
    alias Bolt.Cogs.Tag.Read

    Read.command(msg, args)
  end
end
