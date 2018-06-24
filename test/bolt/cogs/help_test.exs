defmodule BoltTest.Cogs.Help do
  use ExUnit.Case, async: true

  describe "format_command_detail/1" do
    alias Bolt.Cogs.Help

    test "returns an embed" do
      alias Nostrum.Struct.Embed

      assert %Embed{} =
               Help.format_command_detail("test command", ["test usage"], "test description")
    end

    test "inserts prefix in front of usage lines" do
      alias Nostrum.Struct.Embed

      %Embed{description: content} =
        Help.format_command_detail("test command", ["test usage"], "test description")

      {:ok, prefix} = Application.fetch_env(:bolt, :prefix)
      assert String.contains?(content, "#{prefix}test usage")
    end
  end

  describe "format_command_not_found/1" do
    alias Bolt.Cogs.Help

    test "returns an embed" do
      alias Nostrum.Struct.Embed

      assert %Embed{} = Help.format_command_not_found("test command")
    end

    test "shows the not found command in embed title" do
      title = Help.format_command_not_found("test command").title
      assert String.contains?(title, "test command")
    end
  end
end
