defmodule Bolt.Cogs.Note do
  alias Bolt.Constants
  alias Bolt.Converters
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.User

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
           {:ok, created_infraction} <- Repo.insert(changeset) do
        %Embed{
          title: "Created a note for #{User.full_name(member.user)}",
          description: "Use `infr detail #{created_infraction.id}` to view it.",
          color: Constants.color_green()
        }
      else
        "" ->
          %Embed{
            title: "Invalid arguments given",
            description: "The note given may not be empty.",
            color: Constants.color_red()
          }

        {:error, reason} ->
          %Embed{
            title: "Failed to create a note",
            description: reason,
            color: Constants.color_red()
          }
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end
end
