defmodule Bolt.Cogs.Mute do
  @moduledoc false
  @behaviour Nosedrum.Command

  alias Bolt.Commander.Checks
  alias Bolt.Converters
  alias Bolt.{ErrorFormatters, ModLog, Repo}
  alias Bolt.Schema.{Infraction, MuteRole}
  alias Nostrum.Api
  alias Nostrum.Struct.User

  @impl true
  def usage, do: ["mute <user:member> [reason:str...]"]

  @impl true
  def description,
    do: """
    Mutes the given `user` by applying the configured mute role.
    The user can be unmuted by using `.unmute`.
    To apply a temporary mute, use `.tempmute`.
    Requires the `MANAGE_MESSAGES` permission.

    ```rs
    // Mute @Dude#0007.
    .mute @Dude#0007

    // Mute @Dude#0007 with a reason provided for the infraction.
    .mute @Dude#0007 spamming in #general
    ```
    """

  @impl true
  def predicates, do: [&Checks.guild_only/1, &Checks.can_manage_messages?/1]

  @impl true
  def command(msg, [user_str | reason_list]) do
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
           {:ok} <- Api.add_guild_member_role(msg.guild_id, member.user.id, mute_role_id),
           infraction_map <- %{
             type: "mute",
             guild_id: msg.guild_id,
             actor_id: msg.author.id,
             user_id: member.user.id,
             reason: if(reason != "", do: reason, else: nil),
             data: %{
               "role_id" => mute_role_id
             }
           },
           changeset <- Infraction.changeset(%Infraction{}, infraction_map),
           {:ok, _infraction} <- Repo.insert(changeset) do
        ModLog.emit(
          msg.guild_id,
          "INFRACTION_CREATE",
          "#{User.full_name(msg.author)} has muted #{User.full_name(member.user)} " <>
            "(`#{member.user.id}`) #{if reason != "", do: "(`#{reason}`)", else: ""}"
        )

        if reason == "" do
          "👌 #{User.full_name(member.user)} is now muted"
        else
          "👌 #{User.full_name(member.user)} is now muted (``#{reason}``)"
        end
      else
        nil ->
          "🚫 no mute role is configured"

        %Infraction{id: active_id} ->
          "🚫 that user is already muted (##{active_id})"

        error ->
          ErrorFormatters.fmt(msg, error)
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `#{List.first(usage())}`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
