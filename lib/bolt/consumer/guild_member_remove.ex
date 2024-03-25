defmodule Bolt.Consumer.GuildMemberRemove do
  @moduledoc "Handles the `GUILD_MEMBER_REMOVE` event."

  alias Bolt.Humanizer
  alias Bolt.ModLog
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Struct.Guild
  import Ecto.Query, only: [from: 2]

  @spec handle(Guild.id(), Guild.Member.t()) :: ModLog.on_emit()
  def handle(guild_id, member) do
    active_timed_infractions_query =
      from(
        infr in Infraction,
        where:
          infr.guild_id == ^guild_id and infr.active and infr.user_id == ^member.user_id and
            infr.type in ["tempmute", "mute", "temprole"],
        select: infr.id
      )

    active_timed_infractions = Repo.all(active_timed_infractions_query)

    log_with_infractions(guild_id, member, active_timed_infractions)
  end

  @spec log_with_infractions(Guild.id(), Guild.Member.t(), [Infraction]) :: ModLog.on_emit()
  defp log_with_infractions(guild_id, member, active_infractions)

  defp log_with_infractions(guild_id, member, []) do
    ModLog.emit(
      guild_id,
      "GUILD_MEMBER_REMOVE",
      "#{Humanizer.human_user(member.user_id)} has left"
    )
  end

  defp log_with_infractions(guild_id, member, active_infractions) do
    infraction_ids =
      active_infractions
      |> Stream.map(&"##{&1}")
      |> Enum.join(", ")

    ModLog.emit(
      guild_id,
      "GUILD_MEMBER_REMOVE",
      "#{Humanizer.human_user(member.user_id)} has left " <>
        "- had #{length(active_infractions)} active infraction(s) (#{infraction_ids})"
    )
  end
end
