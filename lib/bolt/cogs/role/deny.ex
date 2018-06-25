defmodule Bolt.Cogs.Role.Deny do
  @moduledoc false

  alias Bolt.Converters
  alias Bolt.Helpers
  alias Bolt.Repo
  alias Bolt.Schema.SelfAssignableRoles
  alias Nostrum.Api

  def command(msg, role_name) do
    response =
      case Converters.to_role(msg.guild_id, role_name, true) do
        {:ok, role} ->
          existing_row = Repo.get(SelfAssignableRoles, msg.guild_id)

          cond do
            existing_row == nil ->
              "🚫 this guild has no self-assignable roles"

            role.id not in existing_row.roles ->
              "🚫 role `#{Helpers.clean_content(role.name)}` is not self-assignable"

            true ->
              updated_row = %{
                roles: Enum.reject(existing_row.roles, &(&1 == role.id))
              }

              changeset = SelfAssignableRoles.changeset(existing_row, updated_row)
              {:ok, _updated_row} = Repo.update(changeset)
              "👌 role `#{Helpers.clean_content(role.name)}` is no longer self-assignable"
          end

        {:error, reason} ->
          "🚫 cannot convert `#{Helpers.clean_content(role_name)}` to `role`: #{reason}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
