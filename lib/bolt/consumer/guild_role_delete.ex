defmodule Bolt.Consumer.GuildRoleDelete do
  @moduledoc "Handles the `GUILD_ROLE_DELETE` event."

  alias Bolt.{Helpers, ModLog, Repo}
  alias Bolt.Schema.SelfAssignableRoles
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.Role

  @spec handle(Guild.id(), Role.t()) :: ModLog.on_emit() | :noop
  def handle(guild_id, deleted_role) do
    case Repo.get(SelfAssignableRoles, guild_id) do
      %SelfAssignableRoles{roles: role_list} = sar_row ->
        if deleted_role.id in role_list do
          updated_roles = Enum.reject(role_list, &(&1 == deleted_role.id))
          changeset = SelfAssignableRoles.changeset(sar_row, %{roles: updated_roles})
          Repo.update(changeset)

          ModLog.emit(
            guild_id,
            "CONFIG_UPDATE",
            "self-assignable role *#{Helpers.clean_content(deleted_role.name)}*"
            <> " was deleted and automatically removed from the self-assignable roles"
          )
        else
          :noop
        end

      _ ->
        :noop
    end

    ModLog.emit(
      guild_id,
      "GUILD_ROLE_DELETE",
      "role #{Helpers.clean_content(deleted_role.name)} (`#{deleted_role.id}`) was deleted"
    )
  end
end
