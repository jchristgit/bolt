defmodule Bolt.Humanizer do
  @moduledoc "Produces human-readable descriptions from snowflakes."

  alias Nostrum.Cache.{GuildCache, UserCache}
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Role
  alias Nostrum.Struct.User
  import Nosedrum.Helpers, only: [escape_server_mentions: 1]
  require Logger

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

  @doc "Humanize a user."
  @spec human_user(User.id()) :: String.t()
  def human_user(user_id) do
    case UserCache.get(user_id) do
      {:ok, user} ->
        escape_server_mentions("#{User.full_name(user)} (`#{user_id}`)")

      _other ->
        "`#{user_id}`"
    end
  end
end
