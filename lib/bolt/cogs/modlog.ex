defmodule Bolt.Cogs.ModLog do
  @moduledoc false

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, ["status"]) do
  end
end
