defmodule BoltTest do
  use ExUnit.Case
  doctest Bolt

  test "greets the world" do
    assert Bolt.hello() == :world
  end
end
