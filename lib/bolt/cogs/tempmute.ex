defmodule Bolt.Cogs.Tempmute do
  @moduledoc false
  @behaviour Nosedrum.Command

  alias Bolt.Commander.Checks
  alias Bolt.Converters
  alias Bolt.ErrorFormatters
  alias Bolt.Events.Handler
  alias Bolt.{Helpers, ModLog, Parsers, Repo}
  alias Bolt.Schema.{Infraction, MuteRole}
  alias Nostrum.Api
  alias Nostrum.Struct.User

  @impl true
  def usage, do: ["tempmute <user:member> <duration:duration> [reason:str...]"]

  @impl true
  def description,
    do: """
    Temporarily mutes the given `user` by applying the configured mute role.
    Requires the `MANAGE_MESSAGES` permission.

    ```rs
    // Mute @Dude#0007 for 2 days and 12 hours.
    .tempmute @Dude#0007 2d12h

    // Mute @Dude#0007 for 5 hours with a reason provided for the infraction.
    .tempmute @Dude#0007 5h spamming in #general
    ```
    """

  @impl true
  def predicates, do: [&Checks.guild_only/1, &Checks.can_manage_messages?/1]

  @impl true
  def command(msg, [user_str, duration | reason_list]) do
    reason = Enum.join(reason_list, " ")

    response =
      with {:ok, member} <- Converters.to_member(msg.guild_id, user_str),
           nil <-
             Repo.get_by(Infraction,
               guild_id: msg.guild_id,
               user_id: member.user.id,
               type: "mute",
               active: true
             ),
           %MuteRole{role_id: mute_role_id} <- Repo.get(MuteRole, msg.guild_id),
           {:ok, expiry} <- Parsers.human_future_date(duration),
           {:ok} <- Api.add_guild_member_role(msg.guild_id, member.user.id, mute_role_id),
           infraction_map <- %{
             type: "mute",
             guild_id: msg.guild_id,
             actor_id: msg.author.id,
             user_id: member.user.id,
             expires_at: expiry,
             reason: if(reason != "", do: reason, else: nil),
             data: %{
               "role_id" => mute_role_id
             }
           },
           {:ok, _struct} <- Handler.create(infraction_map) do
        ModLog.emit(
          msg.guild_id,
          "INFRACTION_CREATE",
          "#{User.full_name(msg.author)} has temporarily muted #{User.full_name(member.user)} " <>
            "(`#{member.user.id}`) until #{Helpers.datetime_to_human(expiry)}" <>
            if(reason != "", do: " (``#{reason}``)", else: "")
        )

        base_response =
          "👌 #{User.full_name(member.user)} is now muted until #{
            Helpers.datetime_to_human(expiry)
          }"

        if reason do
          base_response <> " (`#{reason}`)"
        else
          base_response
        end
      else
        nil ->
          "🚫 no mute role is set up on this server"

        %Infraction{id: active_id} ->
          "🚫 that user is already muted (##{active_id})"

        error ->
          ErrorFormatters.fmt(msg, error)
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "ℹ️  usage: `#{List.first(usage())}`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
