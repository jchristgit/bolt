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

      guild_id = 219501
      role_id = 1295015
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

    test "returns escaped role name on known roles", %{guild_id: guild_id, role_id: role_id, role_name: role_name} do
      expected_name = escape_server_mentions(role_name)

      refute expected_name =~ "@everyone"
      assert "#{expected_name} (`#{role_id}`)" == Humanizer.human_role(guild_id, role_id)
      refute Humanizer.human_role(guild_id, role_id) =~ "@everyone"
    end
  end
end
