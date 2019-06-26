defmodule Bolt.Humanizer do
  @moduledoc "Produces human-readable descriptions from snowflakes."

  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Role
  import Nosedrum.Helpers, only: [escape_server_mentions: 1]

  @doc "Humanize a role."
  @spec human_role(Guild.id(), Role.id()) :: String.t()
  def human_role(guild_id, role_id) do
    case GuildCache.select_by([id: guild_id], &Map.get(&1.roles, role_id)) do
      {:ok, role} when role != nil ->
        escape_server_mentions("#{role.name} (`#{role_id}`)")

      _other ->
        "`#{role_id}`"
    end
  end
end
