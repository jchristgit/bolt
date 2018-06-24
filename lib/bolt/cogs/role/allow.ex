defmodule Bolt.Cogs.Role.Allow do
  alias Bolt.Converters
  alias Bolt.Helpers
  alias Bolt.Repo
  alias Bolt.Schema.SelfAssignableRoles
  alias Nostrum.Api

  def command(msg, role_name) do
    case Converters.to_role(msg.guild_id, role_name, true) do
      {:ok, role} ->
        existing_row = Repo.get(SelfAssignableRoles, msg.guild_id)
        response = cond do
          existing_row == nil ->
            new_row = %{
              guild_id: msg.guild_id,
              roles: [role.id]
            }
            changeset = SelfAssignableRoles.changeset(%SelfAssignableRoles{}, new_row)
            {:ok, _created_row} = Repo.insert(changeset)
            "👌 role `#{Helpers.clean_content(role.name)}` is now self-assignable"

          role.id in existing_row.roles ->
            "🚫 role `#{Helpers.clean_content(role.name)}` is already self-assignable"

          true ->
            updated_row = %{
              roles: existing_row.roles ++ [role.id]
            }
            changeset = SelfAssignableRoles.changeset(existing_row, updated_row)
            {:ok, _updated_row} = Repo.update(changeset)
            "👌 role `#{Helpers.clean_content(role.name)}` is now self-assignable"
        end
        {:ok, _msg} = Api.create_message(msg.channel_id, response)


      {:error, reason} ->
        response = "🚫 cannot convert `#{Helpers.clean_content(role_name)}` to `role`: #{reason}"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end
end
