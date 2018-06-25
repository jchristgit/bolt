defmodule Bolt.Cogs.ModLog do
  @moduledoc false

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, ["status" | args]) do
    alias Bolt.Cogs.ModLog.Status

    Status.command(msg, args)
  end

  def command(msg, ["set" | args]) do
    alias Bolt.Cogs.ModLog.Set

    Set.command(msg, args)
  end

  def command(msg, ["unset" | args]) do
    alias Bolt.Cogs.ModLog.Unset

    Unset.command(msg, args)
  end
end
