defmodule BoltTest.Commander.Parsers do
  use ExUnit.Case, async: true

  describe "Parsers.passthrough/1" do
    alias Bolt.Commander.Parsers

    test "passes arguments through without doing anything" do
      assert Parsers.passthrough([]) == []
      assert Parsers.passthrough(["arg"]) == ["arg"]
      assert Parsers.passthrough(["arg", "u", "ments"]) == ["arg", "u", "ments"]
    end
  end

  describe "Parsers.join/1" do
    alias Bolt.Commander.Parsers

    test "joins arguments by spaces" do
      assert Parsers.join(["hello", "world"]) == "hello world"
      assert Parsers.join(["a", "b", "c"]) == "a b c"
    end

    test "returns first element if there is only one argument" do
      assert Parsers.join(["test"]) == "test"
    end

    test "returns an empty string with no arguments given" do
      assert Parsers.join([]) == ""
    end
  end
end
