defmodule Bolt.Events.Deserializer do
  @moduledoc "Deserializes JSONB data from rows from the `events` into Elixir functions."

  alias Bolt.Schema.Infraction

  @spec deserialize(Infraction) :: (() -> any())
  def deserialize(%Infraction{
        type: "temprole",
        guild_id: guild_id,
        user_id: user_id,
        data: %{"role_id" => role_id}
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

  def deserialize(%Infraction{
        type: "tempban",
        guild_id: guild_id,
        user_id: user_id
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
        {:error, %{message: %{"message" => reason}}} ->
          ModLog.emit(
            guild_id,
            "INFRACTION_EVENTS",
            "could NOT remove temporary ban for `#{user_id}` (#{reason})"
          )

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

  def deserialize(%Infraction{type: "forced_nick"} = infraction) do
    func = fn ->
      alias Bolt.Repo
      alias Bolt.Schema.Infraction

      changeset = Infraction.changeset(infraction, %{active: false})
      Repo.update(changeset)
    end

    {:ok, func}
  end

  def deserialize(%Infraction{
        type: "mute",
        id: infraction_id,
        guild_id: guild_id,
        user_id: user_id,
        data: %{
          "role_id" => mute_role_id
        }
      }) do
    func = fn ->
      alias Bolt.ModLog
      alias Nostrum.Api

      modlog_message =
        case Api.remove_guild_member_role(guild_id, user_id, mute_role_id) do
          {:ok} ->
            "user `#{user_id}` was unmuted (##{infraction_id})"

          {:error, %{message: %{"message" => reason}}} ->
            "failed to unmute `#{user_id}`, got API error: #{reason} (infraction ##{infraction_id})"
        end

      ModLog.emit(
        guild_id,
        "INFRACTION_EVENTS",
        modlog_message
      )
    end

    {:ok, func}
  end
end
