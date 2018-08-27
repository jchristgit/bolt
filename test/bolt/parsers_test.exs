defmodule BoltTest.Parsers do
  use ExUnit.Case, async: true

  describe "Parsers.duration_string_to_seconds/1" do
    alias Bolt.Parsers

    test "converts `now` properly" do
      assert Parsers.duration_string_to_seconds("now") == {:ok, 0}
    end

    test "converts seconds properly" do
      assert Parsers.duration_string_to_seconds("10s") == {:ok, 10}
      assert Parsers.duration_string_to_seconds("30s") == {:ok, 30}
      assert Parsers.duration_string_to_seconds("5s") == {:ok, 5}
    end

    test "convert minutes properly" do
      assert Parsers.duration_string_to_seconds("1m") == {:ok, 60}
      assert Parsers.duration_string_to_seconds("30m") == {:ok, 60 * 30}
    end

    test "converts hours properly" do
      assert Parsers.duration_string_to_seconds("1h") == {:ok, 60 * 60}
      assert Parsers.duration_string_to_seconds("2h") == {:ok, 60 * 60 * 2}
    end

    test "converts days properly" do
      assert Parsers.duration_string_to_seconds("1d") == {:ok, 60 * 60 * 24}
      assert Parsers.duration_string_to_seconds("5d") == {:ok, 60 * 60 * 24 * 5}
    end

    test "converts weeks properly" do
      assert Parsers.duration_string_to_seconds("1w") == {:ok, 60 * 60 * 24 * 7}
      assert Parsers.duration_string_to_seconds("3w") == {:ok, 60 * 60 * 24 * 7 * 3}
    end

    test "returns total seconds for single units" do
      assert Parsers.duration_string_to_seconds("30s") == {:ok, 30}
      assert Parsers.duration_string_to_seconds("500s") == {:ok, 500}
      assert Parsers.duration_string_to_seconds("1m") == {:ok, 60}
      assert Parsers.duration_string_to_seconds("1h") == {:ok, 3_600}
    end

    test "returns total seconds for combined strings" do
      assert Parsers.duration_string_to_seconds("1m30s") == {:ok, 90}
      assert Parsers.duration_string_to_seconds("3h2m40s") == {:ok, 10_960}
    end

    test "errors with an empty string" do
      assert match?({:error, _}, Parsers.duration_string_to_seconds(""))
    end

    test "errors with only numbers" do
      assert match?({:error, _}, Parsers.duration_string_to_seconds("33"))
      assert match?({:error, _}, Parsers.duration_string_to_seconds("5"))
    end

    test "errors with only symbols" do
      assert match?({:error, _}, Parsers.duration_string_to_seconds("d"))
      assert match?({:error, _}, Parsers.duration_string_to_seconds("h"))
      assert match?({:error, _}, Parsers.duration_string_to_seconds("abc"))
    end

    test "errors with invalid unit" do
      assert match?({:error, _}, Parsers.duration_string_to_seconds("3z"))
      assert match?({:error, _}, Parsers.duration_string_to_seconds("5d3z"))
    end
  end

  describe "Parsers.human_future_date/2" do
    alias Bolt.Parsers

    setup do
      %{datetime: DateTime.utc_now()}
    end

    test "returns error with invalid input" do
      assert match?({:error, _}, Parsers.human_future_date("3"))
      assert match?({:error, _}, Parsers.human_future_date("d"))
      assert match?({:error, _}, Parsers.human_future_date("."))
      assert match?({:error, _}, Parsers.human_future_date(""))
      assert match?({:error, _}, Parsers.human_future_date("  "))
    end

    test "adds seconds to timestamp if given", %{datetime: datetime} do
      dt_plus_30_seconds =
        datetime
        |> DateTime.to_unix()
        |> Kernel.+(30)
        |> DateTime.from_unix!()

      assert Parsers.human_future_date("30s", datetime) == {:ok, dt_plus_30_seconds}
    end
  end
end
