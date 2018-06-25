defmodule Bolt.Cogs.Assign do
  @moduledoc false

  alias Bolt.Converters
  alias Bolt.Helpers
  alias Bolt.Repo
  alias Bolt.Schema.SelfAssignableRoles
  alias Nostrum.Api

  def command(msg, role_name) do
    response =
      with roles_row when roles_row != nil <- Repo.get(SelfAssignableRoles, msg.guild_id),
           {:ok, role} <- Converters.to_role(msg.guild_id, role_name, true),
           true <- role.id in roles_row.roles,
           {:ok} <- Api.add_guild_member_role(msg.guild_id, msg.author.id, role.id) do
        "👌 gave you the `#{Helpers.clean_content(role.name)}` role"
      else
        nil ->
          "🚫 this guild has no self-assignable roles configured"

        false ->
          "🚫 that role is not self-assignable"

        {:error, %{status_code: status, message: %{"message" => reason}}} ->
          "🚫 API error: #{reason} (status code #{status})"

        {:error, reason} ->
          "🚫 #{Helpers.clean_content(reason)}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
