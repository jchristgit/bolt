defmodule BoltTest.Cogs.Help do
  use ExUnit.Case, async: true

  describe "format_command_detail/1" do
    alias Bolt.Cogs.Help
    alias Nostrum.Struct.Embed

    test "returns an embed" do
      assert %Embed{} =
               Help.format_command_detail("test command", ["test usage"], "test description")
    end
  end
end
