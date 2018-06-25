defmodule Bolt.Cogs.Dummy do
  @moduledoc "A dummy cog, useful when a callback is required but not wanted."

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: no_return()
  def command(_msg, _args) do
  end
end
