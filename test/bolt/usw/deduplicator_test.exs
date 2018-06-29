defmodule BoltTest.USW.Deduplicator do
  use ExUnit.Case, async: true

  describe "empty deduplicator" do
    alias Bolt.USW.Deduplicator

    setup do
      deduplicator = start_supervised!(Deduplicator)
      %{deduplicator: deduplicator}
    end

    test "returns `false` for unknown users in `Deduplicator.contains?/1`", %{
      deduplicator: deduplicator
    } do
      refute Deduplicator.contains?(deduplicator, 0)
      refute Deduplicator.contains?(deduplicator, -1)
      refute Deduplicator.contains?(deduplicator, 42)
    end

    test "returns `:ok` for removing unknown users in `Deduplicator.remove/1`", %{
      deduplicator: deduplicator
    } do
      assert Deduplicator.remove(deduplicator, 0) == :ok
      assert Deduplicator.remove(deduplicator, 5) == :ok
    end
  end

  describe "deduplicator with single user" do
    alias Bolt.USW.Deduplicator

    setup do
      deduplicator = start_supervised!(Deduplicator)
      expiry_ms = 1000
      assert match?({:ok, _reference}, Deduplicator.add(deduplicator, 50, expiry_ms))
      %{deduplicator: deduplicator}
    end

    test "returns `true` for added user in `Deduplicator.contains?/1`", %{
      deduplicator: deduplicator
    } do
      assert Deduplicator.contains?(deduplicator, 50)
    end

    test "returns `false` for unknown user in `Deduplicator.contains?/1`", %{
      deduplicator: deduplicator
    } do
      refute Deduplicator.contains?(deduplicator, 3)
    end
  end

  describe "the deduplicator" do
    alias Bolt.USW.Deduplicator

    setup do
      deduplicator = start_supervised!(Deduplicator)
      %{deduplicator: deduplicator}
    end

    test "adds new users and removes them after the given expiry", %{deduplicator: deduplicator} do
      expiry_ms = 10
      assert match?({:ok, _tref}, Deduplicator.add(deduplicator, 42, expiry_ms))
      assert Deduplicator.contains?(deduplicator, 42)

      # If we just sleep for `expiry_ms`, the Deduplicator doesn't seem to manage removing the
      # user we added properly. When we sleep for exactly one millisecond longer, it works.
      # If someone knows what is causing this, I'd be very interested.
      Process.sleep(expiry_ms + 1)
      refute Deduplicator.contains?(deduplicator, 42)
    end
  end
end
