defmodule Bolt.Cogs.Unmute do
  @moduledoc false
  @behaviour Nosedrum.Command

  alias Bolt.Converters
  alias Bolt.ErrorFormatters
  alias Bolt.Events.Handler
  alias Bolt.Schema.Infraction
  alias Bolt.{ModLog, Repo}
  alias Ecto.Changeset
  alias Nosedrum.Predicates
  alias Nostrum.Api
  alias Nostrum.Struct.User
  import Ecto.Query, only: [from: 2]

  @impl true
  def usage, do: ["unmute <user:member...>"]

  @impl true
  def description,
    do: """
    Unmutes the given `user`. Requires that the user is currently muted.
    Requires the `MANAGE_MESSAGES` permission.
    """

  @impl true
  def predicates, do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_messages)]

  @impl true
  def command(msg, user_list) when user_list != [] do
    response =
      with {:ok, member} <- Converters.to_member(msg.guild_id, Enum.join(user_list, " ")),
           mute_query <-
             from(
               infr in Infraction,
               where:
                 infr.guild_id == ^msg.guild_id and infr.user_id == ^member.user.id and
                   infr.type == "mute" and infr.active
             ),
           mute_infraction when mute_infraction != nil <- Repo.one(mute_query),
           {:ok} <-
             Api.remove_guild_member_role(
               mute_infraction.guild_id,
               mute_infraction.user_id,
               Map.get(mute_infraction.data, "role_id")
             ),
           {:ok, updated_infraction} <- expire_mute(mute_infraction) do
        ModLog.emit(
          msg.guild_id,
          "INFRACTION_UPDATE",
          "#{User.full_name(msg.author)} unmuted " <>
            "#{User.full_name(member.user)} (##{updated_infraction.id})"
        )

        "👌 #{User.full_name(member.user)} is now unmuted"
      else
        nil ->
          "🚫 there is no active mute or tempmute for the given user"

        error ->
          ErrorFormatters.fmt(msg, error)
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `#{List.first(usage())}`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  @spec expire_mute(Infraction) :: {:ok, Infraction} | {:error, String.t() | Changeset.t()}
  defp expire_mute(infraction)

  # Untimed mute, not registered in the event handler.
  defp expire_mute(%Infraction{expires_at: nil} = infraction) do
    infraction
    |> Infraction.changeset(%{active: false})
    |> Repo.update()
  end

  # Timed mute, registered in the events handler.
  # We need to stop the timer to prevent bolt from attempting to remove the role by itself.
  defp expire_mute(infraction) do
    Handler.update(infraction, %{active: false})
  end
end
