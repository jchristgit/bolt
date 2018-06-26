defmodule Bolt.Cogs.Sudo do
  @moduledoc false

  alias Nostrum.Api

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, ["guilds" | args]) do
    alias Bolt.Cogs.Sudo.Guilds

    Guilds.command(msg, args)
  end

  def command(msg, ["leaveguild" | args]) do
    alias Bolt.Cogs.Sudo.LeaveGuild

    LeaveGuild.command(msg, args)
  end

  def command(msg, ["send" | args]) do
    alias Bolt.Cogs.Sudo.Send

    Send.command(msg, args)
  end

  def command(msg, ["log" | args]) do
    alias Bolt.Cogs.Sudo.Log

    Log.command(msg, args)
  end

  def command(msg, _args) do
    response = "🚫 unknown subcommand"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
