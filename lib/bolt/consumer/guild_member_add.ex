defmodule Bolt.Consumer.GuildMemberAdd do
  @moduledoc "Handles the `GUILD_MEMBER_ADD` event."

  alias Bolt.{Helpers, ModLog, Repo}
  alias Bolt.Schema.{Infraction, JoinAction}
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Snowflake
  alias Nostrum.Struct.{Guild, Message, User}
  import Ecto.Query, only: [from: 2]

  @spec handle(Guild.id(), Guild.Member.t()) :: {:ok, Message.t()}
  def handle(guild_id, member) do
    creation_datetime = Snowflake.creation_time(member.user.id)

    ModLog.emit(
      guild_id,
      "GUILD_MEMBER_ADD",
      "#{User.full_name(member.user)} (`#{member.user.id}`) has joined " <>
        "- account created #{Helpers.datetime_to_human(creation_datetime)}"
    )

    check_active_temprole(guild_id, member)
    execute_join_actions(guild_id, member)
    instrument(guild_id)
  end

  @spec check_active_temprole(Guild.id(), Guild.Member.t()) :: :ignored | ModLog.on_emit()
  defp check_active_temprole(guild_id, member) do
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
        :ignored

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

  @spec execute_join_actions(Guild.id(), Guild.Member.t()) :: :ok
  defp execute_join_actions(guild_id, member) do
    query = from(action in JoinAction, where: action.guild_id == ^guild_id)

    query
    |> Repo.all()
    |> Enum.each(&execute_single_action(&1, guild_id, member))
  end

  @spec execute_single_action(JoinAction, Guild.id(), Guild.Member.t()) ::
          {:ok, Message.t()} | :ignored | :ok
  defp execute_single_action(action, guild_id, member)

  defp execute_single_action(
         %JoinAction{action: "add_role", data: %{"role_id" => role_id}},
         guild_id,
         member
       ) do
    case Api.add_guild_member_role(guild_id, member.user.id, role_id) do
      {:ok} ->
        :ok

      {:error, %{status_code: status, message: %{"message" => reason}}} ->
        ModLog.emit(
          guild_id,
          "ERROR",
          "tried adding role `#{role_id}` to #{User.full_name(member.user)} (`#{member.user.id}`) " <>
            "but got an API error: #{reason} (status code #{status})"
        )
    end
  end

  defp execute_single_action(
         %JoinAction{
           action: "send_guild",
           data: %{"channel_id" => target_channel, "template" => template}
         },
         _guild_id,
         member
       ) do
    text = String.replace(template, "{mention}", User.mention(member.user))

    Api.create_message(target_channel, text)
  end

  defp execute_single_action(
         %JoinAction{action: "send_dm", data: %{"template" => template}},
         _guild_id,
         member
       ) do
    text = String.replace(template, "{mention}", User.mention(member.user))

    case Api.create_dm(member.user.id) do
      {:ok, dm_channel} ->
        Api.create_message(dm_channel.id, text)

      _error ->
        :ignored
    end
  end

  @spec instrument(Guild.id()) :: :ok
  defp instrument(guild_id) do
    with {:ok, count} when count != nil <-
           GuildCache.select_by(%{id: guild_id}, & &1.member_count) do
      :ok = :prometheus_gauge.set(:bolt_guild_members, [guild_id], count)
    end
  end
end
