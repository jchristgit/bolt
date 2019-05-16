defmodule Bolt.Consumer.GuildRoleUpdate do
  @moduledoc "Handles the `GUILD_ROLE_CREATE` event."

  alias Bolt.{Helpers, ModLog}
  alias Nostrum.Permission
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Role

  @spec handle(Guild.id(), Role.t(), Role.t()) :: ModLog.on_emit()
  def handle(guild_id, old_role, new_role) do
    diff_string =
      []
      |> add_if_different(old_role, new_role, :color)
      |> add_if_different(old_role, new_role, :hoist)
      |> add_if_different(old_role, new_role, :managed)
      |> add_if_different(old_role, new_role, :mentionable)
      |> add_if_different(old_role, new_role, :name)
      |> add_if_different(old_role, new_role, :permissions)
      |> Enum.join(", ")

    unless diff_string == "" do
      ModLog.emit(
        guild_id,
        "GUILD_ROLE_UPDATE",
        "role #{Helpers.clean_content(old_role.name)} (`#{old_role.id}`) #{diff_string}"
      )
    end
  end

  @spec add_if_different([String.t()], Role.t(), Role.t(), atom()) :: [String.t()]
  defp add_if_different(diff_list, old_role, new_role, :permissions) do
    old_perms = Permission.from_bitset(old_role.permissions)
    new_perms = Permission.from_bitset(new_role.permissions)
    difference = List.myers_difference(old_perms, new_perms)

    added_perms = difference |> Keyword.get_values(:ins) |> List.flatten()
    removed_perms = difference |> Keyword.get_values(:del) |> List.flatten()

    diff_list ++
      Enum.map(
        added_perms,
        &"added permission `#{&1}`"
      ) ++
      Enum.map(
        removed_perms,
        &"removed permission `#{&1}`"
      )
  end

  defp add_if_different(diff_list, old_role, new_role, key) do
    old_value = Map.get(old_role, key)
    new_value = Map.get(new_role, key)

    if old_value != new_value do
      cond do
        new_value === true ->
          diff_list ++ ["now #{key}"]

        new_value === false ->
          diff_list ++ ["no longer #{key}"]

        true ->
          description =
            if key == :name do
              "name updated from `#{Helpers.clean_content(old_value)}` " <>
                "to `#{Helpers.clean_content(new_value)}`"
            else
              "#{Atom.to_string(key)} updated from `#{old_value}` to `#{new_value}`"
            end

          diff_list ++ [description]
      end
    else
      diff_list
    end
  end
end
