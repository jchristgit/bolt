defmodule Bolt.Cogs.Note do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.{Converters, Helpers, ModLog, Repo}
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.User

  @impl true
  def usage, do: ["note <user:member> <note:str...>"]

  @impl true
  def description,
    do: """
    Create a note for the given user.
    The note is stored in the infraction database, and can be retrieved later.
    Requires the `MANAGE_MESSAGES` permission.

    **Examples**:
    ```rs
    note @Dude#0001 has an odd affection to ducks
    ```
    """

  @impl true
  def predicates,
    do: [&Bolt.Commander.Checks.guild_only/1, &Bolt.Commander.Checks.can_manage_messages?/1]

  @impl true
  def command(msg, [user | note_list]) do
    response =
      with {:ok, member} <- Converters.to_member(msg.guild_id, user),
           note when note != "" <- Enum.join(note_list, " "),
           infraction = %{
             type: "note",
             guild_id: msg.guild_id,
             user_id: member.user.id,
             actor_id: msg.author.id,
             reason: note
           },
           changeset <- Infraction.changeset(%Infraction{}, infraction),
           {:ok, _created_infraction} <- Repo.insert(changeset) do
        ModLog.emit(
          msg.guild_id,
          "INFRACTION_CREATE",
          "#{User.full_name(msg.author)} (`#{msg.author.id}`) added a note to" <>
            " #{User.full_name(member.user)} (`#{member.user.id}`), contents: `#{note}`"
        )

        "👌 note created for #{User.full_name(member.user)} (`#{member.user.id}`)"
      else
        "" ->
          "🚫 note may not be empty"

        {:error, reason} ->
          "🚫 error: #{Helpers.clean_content(reason)}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `note <user:member> <note:str...>`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
