defmodule Bolt.Consumer.GuildMemberUpdate do
  @moduledoc "Handles the `GUILD_MEMBER_UPDATE` event."

  alias Bolt.{Helpers, ModLog, Repo}
  alias Bolt.Events.Handler
  alias Bolt.Schema.Infraction
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.{Guild, User}
  alias Nostrum.Struct.Guild.Member
  import Ecto.Query, only: [from: 2]

  @spec handle(Guild.id(), Member.t(), Member.t()) :: ModLog.on_emit()
  def handle(guild_id, old_member, new_member) do
    perform_regular_modlog(guild_id, old_member, new_member)

    with role_diff <- List.myers_difference(old_member.roles, new_member.roles),
         removed_roles when removed_roles != [] <- Keyword.get(role_diff, :del, []),
         removed_role_id <- List.first(removed_roles),
         query <-
           from(
             infr in Infraction,
             where:
               infr.guild_id == ^guild_id and infr.user_id == ^new_member.user.id and infr.active and
                 fragment("data->'role_id' = ?", ^removed_role_id) and infr.type == "temprole",
             limit: 1,
             select: infr
           ),
         active_temproles when active_temproles != [] <- Repo.all(query),
         active_temprole <- List.first(active_temproles),
         {:ok, _updated_infraction} <- Handler.update(active_temprole, %{active: false}) do
      ModLog.emit(
        guild_id,
        "INFRACTION_UPDATE",
        "role `#{removed_role_id}` was manually removed from #{User.full_name(new_member.user)}" <>
          " (`#{new_member.user.id}`) while a temprole was active (##{active_temprole.id})" <>
          ", the infraction is now inactive and bolt will not attempt to remove the role"
      )
    else
      _err -> :ignored
    end
  end

  @spec perform_regular_modlog(Guild.id(), Member.t(), Member.t()) :: ModLog.on_emit()
  def perform_regular_modlog(guild_id, old_member, new_member) do
    diff_string =
      []
      |> describe_if_changed(guild_id, old_member, new_member, :deaf)
      |> describe_if_changed(guild_id, old_member, new_member, :mute)
      |> describe_if_changed(guild_id, old_member, new_member, :nick)
      |> describe_if_changed(guild_id, old_member, new_member, :roles)
      |> Enum.join(", ")

    ModLog.emit(
      guild_id,
      "GUILD_MEMBER_UPDATE",
      Helpers.clean_content(
        "#{User.full_name(new_member.user)} (`#{new_member.user.id}`) #{diff_string}"
      )
    )
  end

  @spec describe_if_changed([String.t()], Guild.id(), Member.t(), Member.t(), atom) :: [
          String.t()
        ]
  def describe_if_changed(diff_list, guild_id, old_member, new_member, :roles) do
    role_diff = List.myers_difference(old_member.roles, new_member.roles)

    added_roles = role_diff |> Keyword.get_values(:ins) |> List.flatten()
    removed_roles = role_diff |> Keyword.get_values(:del) |> List.flatten()

    diff_list ++
      Enum.map(
        added_roles,
        &"role added #{format_role(guild_id, &1)}"
      ) ++
      Enum.map(
        removed_roles,
        &"role removed #{format_role(guild_id, &1)}"
      )
  end

  def describe_if_changed(diff_list, _guild_id, old_member, new_member, key) do
    old_value = Map.get(old_member, key)
    new_value = Map.get(new_member, key)

    if old_value != new_value do
      cond do
        new_value === true -> diff_list ++ ["now #{key}"]
        new_value === false -> diff_list ++ ["no longer #{key}"]
        old_value === nil -> diff_list ++ ["added #{key} ``#{new_value}``"]
        new_value === nil -> diff_list ++ ["removed #{key} ``#{old_value}``"]
        true -> diff_list ++ ["updated #{key} from ``#{old_value}`` to ``#{new_value}``"]
      end
    else
      diff_list
    end
  end

  @spec format_role(Guild.id(), Role.id()) :: String.t()
  def format_role(guild_id, role_id) do
    with {:ok, guild} <- GuildCache.get(guild_id),
         role when role != nil <- Enum.find(guild.roles, &(&1.id == role_id)) do
      "``#{role.name}`` (`#{role.id}`)"
    else
      _err -> "#{role_id}"
    end
  end
end
