defmodule Bolt.Commander.Parsers do
  @spec passthrough(String.t()) :: String.t()
  def passthrough(args) do
    args
  end

  @spec join([String.t()]) :: String.t()
  def join(args) do
    Enum.join(args, " ")
  end
end
