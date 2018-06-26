defmodule Bolt.Cogs.Sudo do
  def command(msg, ["guilds" | args]) do
    alias Bolt.Cogs.Sudo.Guilds

    Guilds.command(msg, args)
  end
end
