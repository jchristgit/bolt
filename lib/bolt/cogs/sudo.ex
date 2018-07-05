defmodule Bolt.Cogs.Sudo do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Nostrum.Api

  @impl true
  def usage, do: ["sudo ?"]

  @impl true
  def description,
    do: """
    We trust you have received the usual lecture from the local System Administrator. It usually boils down to these three things:
    #1) Respect the privacy of others.
    #2) Think before you type.
    #3) With great power comes great responsibility.
    """

  @impl true
  def predicates, do: [&Checks.is_superuser?/1]

  @impl true
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
