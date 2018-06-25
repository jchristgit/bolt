defmodule Bolt.Commander.Parsers do
  @moduledoc "Implements various parsers that go from `[String.t()] :: args -> any()`."

  @spec passthrough([String.t()]) :: [String.t()]
  def passthrough(args) do
    args
  end

  @spec join([String.t()]) :: String.t()
  def join(args) do
    Enum.join(args, " ")
  end
end
