defmodule BoltTest.Helpers do
  use ExUnit.Case, async: true

  describe "Helpers.bool_to_human/1" do
    alias Bolt.Helpers

    test "translates bools to yes / no" do
      assert Helpers.bool_to_human(true) == "yes"
      assert Helpers.bool_to_human(false) == "no"
    end
  end

  describe "Helpers.clean_content/1" do
    alias Bolt.Helpers

    test "properly escapes `@everyone` and `@here` mentions" do
      assert Helpers.clean_content("@everyone") == "@\u200Beveryone"
      assert Helpers.clean_content("@here") == "@\u200Bhere"
    end

    test "ignores regular user mentions" do
      assert Helpers.clean_content("<@1920312310>") == "<@1920312310>"
      assert Helpers.clean_content("<@1>") == "<@1>"
    end
  end
end
