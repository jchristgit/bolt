defmodule Bolt.Consumer.GuildMemberAdd do
  @moduledoc "Handles the `GUILD_MEMBER_ADD` event."

  alias Bolt.{Helpers, ModLog, Repo}
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.{Guild, Message, Snowflake, User}
  import Ecto.Query, only: [from: 2]

  @spec handle(Guild.id(), Guild.Member.id()) :: {:ok, Message.t()}
  def handle(guild_id, member) do
    creation_datetime = Snowflake.creation_time(member.user.id)

    ModLog.emit(
      guild_id,
      "GUILD_MEMBER_ADD",
      "#{User.full_name(member.user)} (`#{member.user.id}`) has joined " <>
        "- account created #{Helpers.datetime_to_human(creation_datetime)}"
    )

    query =
      from(
        infr in Infraction,
        where:
          infr.guild_id == ^guild_id and infr.user_id == ^member.user.id and
            infr.type == "temprole" and infr.expires_at > ^DateTime.utc_now(),
        select: infr
      )

    case Repo.all(query) do
      [] ->
        :noop

      infractions ->
        infractions
        |> Enum.each(fn temprole_infraction ->
          with {:ok} <-
                 Api.add_guild_member_role(
                   guild_id,
                   member.user.id,
                   temprole_infraction.data["role_id"]
                 ) do
            ModLog.emit(
              guild_id,
              "INFRACTION_EVENTS",
              "member #{User.full_name(member.user)} (`#{member.user.id}`) with active temprole" <>
                " (`#{temprole_infraction.data["role_id"]}`) rejoined, temporary role was reapplied"
            )
          else
            {:error, %{message: %{"message" => reason}}} ->
              ModLog.emit(
                guild_id,
                "INFRACTION_EVENTS",
                "member #{User.full_name(member.user)} (`#{member.user.id}`) with active temprole" <>
                  " rejoined, but failed to reapply role: `#{reason}`"
              )
          end
        end)
    end
  end
end
