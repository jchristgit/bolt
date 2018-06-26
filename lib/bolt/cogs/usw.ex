defmodule Bolt.Cogs.USW do
  @moduledoc false

  def command(msg, ["status" | args]) do
    alias Bolt.Cogs.USW.Status

    Status.command(msg, args)
  end
end
