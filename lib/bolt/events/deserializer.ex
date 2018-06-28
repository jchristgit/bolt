defmodule Bolt.Events.Deserializer do
  @moduledoc "Deserializes JSONB data from rows from the `events` into Elixir functions."

  alias Bolt.Schema.Event

  @spec valid_events :: [String.t()]
  def valid_events do
    [
      "CREATE_MESSAGE",
      "REMOVE_ROLE",
      "UNBAN_MEMBER"
    ]
  end

  @spec deserialize(%Event{}) :: (() -> any())
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
      alias Bolt.ModLog
      alias Nostrum.Api

      with {:ok} <- Api.remove_guild_member_role(guild_id, user_id, role_id) do
        ModLog.emit(
          guild_id,
          "INFRACTION_EVENTS",
          "removed temporary role `#{role_id}` from `#{user_id}`"
        )
      else
        {:error, %{message: %{"message" => reason}}} ->
          ModLog.emit(
            guild_id,
            "INFRACTION_EVENTS",
            "could NOT remove temporary role `#{role_id}` from `#{user_id}` (#{reason})"
          )

        _error ->
          ModLog.emit(
            guild_id,
            "INFRACTION_EVENTS",
            "could NOT remove temporary role `#{role_id}` from `#{user_id}` (unexpected error)"
          )
      end
    end

    {:ok, func}
  end

  def deserialize(%Event{
        event: "UNBAN_MEMBER",
        data: %{"guild_id" => guild_id, "user_id" => user_id}
      }) do
    func = fn ->
      alias Bolt.ModLog
      alias Nostrum.Api

      with {:ok} <- Api.remove_guild_ban(guild_id, user_id) do
        ModLog.emit(
          guild_id,
          "INFRACTION_EVENTS",
          "removed temporary ban for `#{user_id}`"
        )
      else
        _err ->
          ModLog.emit(
            guild_id,
            "INFRACTION_EVENTS",
            "failed to remove temporary ban for `#{user_id}` (unexpected error)"
          )
      end
    end

    {:ok, func}
  end

  def deserialize(%Event{event: unknown_type}) do
    {:error, "Unknown event type: `#{unknown_type}`"}
  end
end
