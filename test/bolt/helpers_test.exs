defmodule BoltTest.Helpers do
  alias Bolt.Helpers
  use ExUnit.Case, async: true

  describe "Helpers.bool_to_human/1" do
    test "translates bools to yes / no" do
      assert Helpers.bool_to_human(true) == "yes"
      assert Helpers.bool_to_human(false) == "no"
    end
  end

  describe "Helpers.clean_content/1" do
    test "properly escapes `@everyone` and `@here` mentions" do
      assert Helpers.clean_content("@everyone") == "@\u200Beveryone"
      assert Helpers.clean_content("@here") == "@\u200Bhere"
    end

    test "ignores regular user mentions" do
      assert Helpers.clean_content("<@1920312310>") == "<@1920312310>"
      assert Helpers.clean_content("<@1>") == "<@1>"
    end
  end

  describe "Helpers.datetime_to_human/1" do
    test "converts datetimes to discord format" do
      assert "<t:1554300264:R>" = Helpers.datetime_to_human(~U[2019-04-03 14:04:24Z])
      assert "<t:1640025581:R>" = Helpers.datetime_to_human(~U[2021-12-20 18:39:41Z])
    end
  end
end
