defmodule Bolt.Cogs.Warn do
  @moduledoc false

  @behaviour Nosedrum.Command

  alias Bolt.Commander.Checks
  alias Bolt.{Converters, ErrorFormatters, Helpers, ModLog, Repo}
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.User

  @impl true
  def usage, do: ["warn <user:member> <reason:str...>"]

  @impl true
  def description,
    do: """
    Warn the given user for the specified reason.
    The warning is stored in the infraction database, and can be retrieved later.
    Requires the `MANAGE_MESSAGES` permission.

    **Examples**:
    ```rs
    warn @Dude#0001 spamming duck images at #dog-pics
    ```
    """

  @impl true
  def predicates,
    do: [&Checks.guild_only/1, &Checks.can_manage_messages?/1]

  @impl true
  def command(msg, [user | reason_list]) do
    response =
      with reason when reason != "" <- Enum.join(reason_list, " "),
           {:ok, member} <- Converters.to_member(msg.guild_id, user),
           infraction <- %{
             type: "warning",
             guild_id: msg.guild_id,
             user_id: member.user.id,
             actor_id: msg.author.id,
             reason: reason
           },
           changeset <- Infraction.changeset(%Infraction{}, infraction),
           {:ok, _created_infraction} <- Repo.insert(changeset) do
        ModLog.emit(
          msg.guild_id,
          "INFRACTION_CREATE",
          "#{User.full_name(msg.author)} (`#{msg.author.id}`) has warned" <>
            " #{User.full_name(member.user)} (`#{member.user.id}`) with reason `#{reason}`"
        )

        "👌 warned #{User.full_name(member.user)} (`#{Helpers.clean_content(reason)}`)"
      else
        "" ->
          "🚫 must provide a reason to warn the user for"

        error ->
          ErrorFormatters.fmt(msg, error)
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _anything) do
    response = "ℹ️ usage: `warn <user:member> <reason:str...>`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
