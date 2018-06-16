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
end
