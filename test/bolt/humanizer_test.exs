defmodule Bolt.HumanizerTest do
  alias Bolt.Humanizer
  alias Nostrum.Cache.Guild.GuildRegister
  import Nosedrum.Helpers, only: [escape_server_mentions: 1]
  use ExUnit.Case

  describe "human_role/2" do
    setup do
      start_supervised!(Nostrum.Cache.CacheSupervisor)
      :ok
    end

    test "returns role ID only on unknown guilds" do
      assert "`1234`" = Humanizer.human_role(1, 1234)
    end
  end

  describe "human_role/2 with cached guild and role" do
    setup do
      start_supervised!(Nostrum.Cache.CacheSupervisor)

      guild_id = 219_501
      role_id = 1_295_015
      role_name = "Robot with @everyone permissions"

      guild = %{
        id: guild_id,
        channels: %{},
        members: %{},
        roles: %{
          role_id => %{
            name: role_name
          }
        },
        name: "test guild"
      }

      {:ok, _guild} = GuildRegister.create_guild_process(guild_id, guild)
      %{guild_id: guild_id, role_id: role_id, role_name: role_name}
    end

    test "returns role ID only on unknown roles", %{guild_id: guild_id} do
      assert "`-1`" = Humanizer.human_role(guild_id, -1)
    end

    test "returns escaped role name on known roles", %{
      guild_id: guild_id,
      role_id: role_id,
      role_name: role_name
    } do
      expected_name = escape_server_mentions(role_name)

      refute expected_name =~ "@everyone"
      assert "#{expected_name} (`#{role_id}`)" == Humanizer.human_role(guild_id, role_id)
      refute Humanizer.human_role(guild_id, role_id) =~ "@everyone"
    end
  end

  describe "human_user/1" do
    setup do
      # cleaned up at test process exit by the vm
      :users = :ets.new(:users, [:set, :public, :named_table])
      :ok
    end

    test "returns the user ID when not found" do
      assert "`55`" = Humanizer.human_user(55)
    end
  end

  describe "human_user/1 with cached user" do
    setup do
      :users = :ets.new(:users, [:set, :public, :named_table])

      user = %{
        discriminator: "4444",
        id: 120_951,
        username: "@everyone hi"
      }

      true = :ets.insert(:users, {user.id, user})

      %{user: user}
    end

    test "returns escaped user name for known users", %{user: user} do
      expected_name = escape_server_mentions(user.username)

      refute expected_name =~ "@everyone"

      assert "#{expected_name}##{user.discriminator} (`#{user.id}`)" ==
               Humanizer.human_user(user.id)

      refute Humanizer.human_user(user.id) =~ "@everyone"
    end
  end
end
