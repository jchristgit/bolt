defmodule Bolt.Cogs.Remove do
  @moduledoc false

  alias Bolt.Converters
  alias Bolt.Helpers
  alias Bolt.Repo
  alias Bolt.Schema.SelfAssignableRoles
  alias Nostrum.Api

  @spec command(Nostrum.Struct.Message.t(), String.t()) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, role_name) do
    response =
      with roles_row when roles_row != nil <- Repo.get(SelfAssignableRoles, msg.guild_id),
           {:ok, role} <- Converters.to_role(msg.guild_id, role_name, true),
           true <- role.id in roles_row.roles,
           {:ok} <- Api.remove_guild_member_role(msg.guild_id, msg.author.id, role.id) do
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
