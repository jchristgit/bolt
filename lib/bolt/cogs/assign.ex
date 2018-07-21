defmodule Bolt.Cogs.Assign do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.{Converters, ErrorFormatters, Helpers, ModLog, Repo}
  alias Bolt.Schema.SelfAssignableRoles
  alias Nostrum.Api
  alias Nostrum.Struct.User
  require Logger

  @impl true
  def usage, do: ["assign <role:role...>"]

  @impl true
  def description,
    do: """
    Assigns the given self-assignable role to yourself.
    To see which roles are self-assignable, use `lsar`.
    Aliased to `iam`.

    **Examples**:
    ```rs
    // Assign the role 'Movie Nighter'
    assign movie nighter
    ```
    """

  @impl true
  def predicates, do: [&Checks.guild_only/1]

  @impl true
  def parse_args(args), do: Enum.join(args, " ")

  @impl true
  def command(msg, "") do
    response = "🚫 expected the role name to assign, got nothing"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, role_name) do
    response =
      with roles_row when roles_row != nil <- Repo.get(SelfAssignableRoles, msg.guild_id),
           {:ok, role} <- Converters.to_role(msg.guild_id, role_name, true),
           true <- role.id in roles_row.roles,
           {:ok} <- Api.add_guild_member_role(msg.guild_id, msg.author.id, role.id) do
        ModLog.emit(
          msg.guild_id,
          "AUTOMOD",
          "gave #{User.full_name(msg.author)} (`#{msg.author.id}`)" <>
            " the self-assignable role `#{role.name}`"
        )

        "👌 gave you the `#{Helpers.clean_content(role.name)}` role"
      else
        nil ->
          "🚫 this guild has no self-assignable roles configured"

        false ->
          "🚫 that role is not self-assignable"

        error ->
          ErrorFormatters.fmt(msg, error)
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
