defmodule Bolt.Cogs.USW do
  @moduledoc false

  def command(msg, ["status" | args]) do
    alias Bolt.Cogs.USW.Status

    Status.command(msg, args)
  end

  def command(msg, ["set" | args]) do
    alias Bolt.Cogs.USW.Set

    Set.command(msg, args)
  end

  def command(msg, ["unset" | args]) do
    alias Bolt.Cogs.USW.Unset

    Unset.command(msg, args)
  end

  def command(msg, ["punish" | args]) do
    alias Bolt.Cogs.USW.Punish

    Punish.command(msg, args)
  end

  def command(msg, ["escalate" | args]) do
    alias Bolt.Cogs.USW.Escalate

    Escalate.command(msg, args)
  end
end
