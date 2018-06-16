defmodule BoltTest.Commander do
  use ExUnit.Case, async: true

  describe "Commander.try_split/1" do
    alias Bolt.Commander

    test "returns space-separated words without quotes" do
      assert Commander.try_split("good test") == ["good", "test"]
      assert Commander.try_split("hello") == ["hello"]
      assert Commander.try_split("hello there test") == ["hello", "there", "test"]
    end

    test "regards space-surrounded arguments as single words" do
      assert Commander.try_split("\"good test\"") == ["good test"]
      assert Commander.try_split("hello \"to this test\"") == ["hello", "to this test"]
    end

    test "defaults to `String.split/1` with unclosed quotes" do
      assert Commander.try_split("\"hello world") == ["\"hello", "world"]
      assert Commander.try_split("hello world\"") == ["hello", "world\""]
    end
  end
end
