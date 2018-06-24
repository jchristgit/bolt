defmodule Bolt.Events.Deserializer do
  alias Bolt.Schema.Event

  def valid_events() do
    [
      "CREATE_MESSAGE",
      "REMOVE_ROLE",
      "UNBAN_MEMBER"
    ]
  end

  def deserialize(%Event{
        event: "CREATE_MESSAGE",
        data: %{"channel_id" => channel_id, "content" => content}
      }) do
    func = fn ->
      alias Nostrum.Api

      Api.create_message(channel_id, content)
    end

    {:ok, func}
  end

  def deserialize(%Event{
        event: "REMOVE_ROLE",
        data: %{"guild_id" => guild_id, "user_id" => user_id, "role_id" => role_id}
      }) do
    func = fn ->
      alias Nostrum.Api
      alias Bolt.Helpers

      with {:ok, member} <- Helpers.get_member(guild_id, user_id),
           roles <- Enum.reject(member.roles, &(&1 == role_id)),
           {:ok} <- Api.modify_guild_member(guild_id, user_id, roles: roles) do
        :ok
      end
    end

    {:ok, func}
  end

  def deserialize(%Event{
        event: "UNBAN_MEMBER",
        data: %{"guild_id" => guild_id, "user_id" => user_id}
      }) do
    func = fn ->
      alias Nostrum.Api

      Api.remove_guild_ban(guild_id, user_id)
    end

    {:ok, func}
  end

  def deserialize(%Event{event: unknown_type}) do
    {:error, "Unknown event type: `#{unknown_type}`"}
  end

  def deserialize(unknown_event) do
    {:error, "Not an event: #{inspect(unknown_event)}"}
  end
end
