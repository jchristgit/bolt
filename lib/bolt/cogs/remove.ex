defmodule Bolt.Cogs.Remove do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.{Converters, Helpers, ModLog, Repo}
  alias Bolt.Schema.SelfAssignableRoles
  alias Nostrum.Api
  alias Nostrum.Struct.User

  @impl true
  def usage, do: ["remove <role:role...>"]

  @impl true
  def description,
    do: """
    Remove the given self-assignable role from yourself.
    To see which roles are self-assignable, use `lsar`.
    Aliased to `iamn`.

    **Examples**:
    ```rs
    // unassign the role 'Movie Nighter'
    remove movie nighter
    ```
    """

  @impl true
  def predicates, do: [&Bolt.Commander.Checks.guild_only/1]

  @impl true
  def parse_args(args), do: Enum.join(args, " ")

  @impl true
  def command(msg, "") do
    response = "🚫 expected the role name to remove, got nothing"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, role_name) do
    response =
      with roles_row when roles_row != nil <- Repo.get(SelfAssignableRoles, msg.guild_id),
           {:ok, role} <- Converters.to_role(msg.guild_id, role_name, true),
           true <- role.id in roles_row.roles,
           {:ok} <- Api.remove_guild_member_role(msg.guild_id, msg.author.id, role.id) do
        ModLog.emit(
          msg.guild_id,
          "AUTOMOD",
          "removed the self-assignable role `#{role.name}` from" <>
            " #{User.full_name(msg.author)} (`#{msg.author.id}`)"
        )

        "👌 removed the `#{Helpers.clean_content(role.name)}` role from you"
      else
        nil ->
          "🚫 this guild has no self-assignable roles configured"

        false ->
          "🚫 that role is not self-assignable"

        {:error, %{status_code: status, message: %{"message" => reason}}} ->
          "❌ API error: #{reason} (status code #{status})"

        {:error, reason} ->
          "❌ error: #{Helpers.clean_content(reason)}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
