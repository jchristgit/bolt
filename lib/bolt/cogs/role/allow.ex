defmodule Bolt.Cogs.Role.Allow do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.{Converters, Helpers, ModLog, Repo}
  alias Bolt.Schema.SelfAssignableRoles
  alias Nostrum.Api
  alias Nostrum.Struct.User

  @impl true
  def usage, do: ["role allow <role:role...>"]

  @impl true
  def description,
    do: """
    Allow self-assignment of the given role.
    Self-assignable roles are special roles that can be assigned my members through bot commands.
    Requires the `MANAGE_ROLES` permission.

    **Examples**:
    ```rs
    // allow self-assginment of the 'Movie Nighter' role
    role allow movie nighter
    ```
    """

  @impl true
  def predicates,
    do: [&Checks.guild_only/1, &Checks.can_manage_roles?/1]

  @impl true
  def parse_args(args), do: Enum.join(args, " ")

  @impl true
  def command(msg, "") do
    response = "ℹ️ usage: `role allow <role:role>`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, role_name) do
    response =
      case Converters.to_role(msg.guild_id, role_name, true) do
        {:ok, role} ->
          existing_row = Repo.get(SelfAssignableRoles, msg.guild_id)

          cond do
            existing_row == nil ->
              new_row = %{
                guild_id: msg.guild_id,
                roles: [role.id]
              }

              changeset = SelfAssignableRoles.changeset(%SelfAssignableRoles{}, new_row)
              {:ok, _created_row} = Repo.insert(changeset)

              ModLog.emit(
                msg.guild_id,
                "CONFIG_UPDATE",
                "#{User.full_name(msg.author)} (`#{msg.author.id}`) added" <>
                  " `#{role.name}` (`#{role.id}`) to self-assignable roles"
              )

              "👌 role `#{Helpers.clean_content(role.name)}` is now self-assignable"

            role.id in existing_row.roles ->
              "🚫 role `#{Helpers.clean_content(role.name)}` is already self-assignable"

            true ->
              updated_row = %{
                roles: existing_row.roles ++ [role.id]
              }

              changeset = SelfAssignableRoles.changeset(existing_row, updated_row)
              {:ok, _updated_row} = Repo.update(changeset)

              ModLog.emit(
                msg.guild_id,
                "CONFIG_UPDATE",
                "#{User.full_name(msg.author)} (`#{msg.author.id}`) added" <>
                  " `#{role.name}` (`#{role.id}`) to self-assignable roles"
              )

              "👌 role `#{Helpers.clean_content(role.name)}` is now self-assignable"
          end

        {:error, reason} ->
          "🚫 cannot convert `#{Helpers.clean_content(role_name)}` to `role`: #{reason}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
