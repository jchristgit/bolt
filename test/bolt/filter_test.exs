defmodule Bolt.FilterTest do
  use ExUnit.Case, async: true

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Bolt.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Bolt.Repo, {:shared, self()})
  end

  describe "empty database" do
    setup do
      {:ok, pid} = Bolt.Filter.start_link([])
      %{filter_pid: pid}
    end

    test "made the filter build an empty map", %{filter_pid: filter_pid} do
      assert %{} = GenServer.call(filter_pid, :state)
    end

    test "makes the filter return an empty mapset for any string", %{filter_pid: filter_pid} do
      result = GenServer.call(filter_pid, {:search, nil, "hello, world"})
      assert result == []
    end
  end

  describe "database with single guild" do
    alias Bolt.Schema.FilteredWord

    setup do
      row = Bolt.Repo.insert!(%FilteredWord{guild_id: 42, word: "generics"})
      {:ok, pid} = Bolt.Filter.start_link([])
      %{filter_pid: pid, row: row}
    end

    test "made the filter build a map with relevant entries", %{filter_pid: filter_pid, row: row} do
      guild_id = row.guild_id
      assert %{^guild_id => _graph} = GenServer.call(filter_pid, :state)
    end

    test "returns no matches for unknown guilds", %{filter_pid: filter_pid} do
      assert GenServer.call(filter_pid, {:search, 50, "generics"}) == []
    end

    test "returns no matches for unrelated words", %{filter_pid: filter_pid, row: row} do
      assert GenServer.call(filter_pid, {:search, row.guild_id, "whatever"}) == []
    end

    test "returns match for filtered word", %{filter_pid: filter_pid, row: row} do
      expected = [{1, 8, 'generics'}]
      assert GenServer.call(filter_pid, {:search, row.guild_id, "generics"}) == expected
    end

    test "returns one entry per match", %{filter_pid: filter_pid, row: row} do
      expected = [{9, 16, 'generics'}, {1, 8, 'generics'}]

      assert GenServer.call(filter_pid, {:search, row.guild_id, "genericsgenerics"}) == expected
    end
  end

  describe "filter rebuilding" do
    alias Bolt.Schema.FilteredWord

    setup do
      row = Bolt.Repo.insert!(%FilteredWord{guild_id: 42, word: "generics"})
      {:ok, pid} = Bolt.Filter.start_link([])
      %{filter_pid: pid, row: row}
    end

    test "properly adds new entries", %{filter_pid: filter_pid, row: row} do
      Bolt.Repo.insert!(%FilteredWord{guild_id: row.guild_id, word: "badword"})
      GenServer.cast(filter_pid, {:rebuild, row.guild_id})

      expected = [{1, 7, 'badword'}]
      assert GenServer.call(filter_pid, {:search, row.guild_id, "badword"}) == expected
    end
  end
end
