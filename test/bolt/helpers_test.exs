defmodule BoltTest.Helpers do
  use ExUnit.Case, async: true

  describe "Helpers.clean_content/1" do
    alias Bolt.Helpers

    test "properly escapes `@everyone` and `@here` mentions" do
      assert Helpers.clean_content("@everyone") == "@\u200Beveryone"
      assert Helpers.clean_content("@here") == "@\u200Bhere"
    end
  end
end
