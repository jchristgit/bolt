defmodule Bolt.RaidManagerTest do
  alias Bolt.RaidManager
  use ExUnit.Case

  describe "adding and fetching selections" do
    @guild_id 3333
    @added_members [:foobar]

    setup do
      pid = start_supervised!(RaidManager)
      :ok = RaidManager.add(pid, @guild_id, @added_members)
      %{pid: pid}
    end

    test "returns empty mapset for unknown guilds", %{pid: pid} do
      response = RaidManager.get(pid, 123_190_231)

      assert %MapSet{} = response
      assert Enum.empty?(response)
    end

    test "returns selections for known guilds", %{pid: pid} do
      response = RaidManager.get(pid, @guild_id)

      assert %MapSet{} = response
      assert MapSet.equal?(response, MapSet.new(@added_members))
    end
  end

  describe "deleting selections" do
    @guild_id 120_914
    @added_members [:baz]

    setup do
      pid = start_supervised!(RaidManager)
      :ok = RaidManager.add(pid, @guild_id, @added_members)
      %{pid: pid}
    end

    test "deletes properly", %{pid: pid} do
      refute Enum.empty?(RaidManager.get(pid, @guild_id))
      :ok = RaidManager.drop(pid, @guild_id)
      assert Enum.empty?(RaidManager.get(pid, @guild_id))
    end
  end
end
