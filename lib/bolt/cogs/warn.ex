defmodule Bolt.Cogs.Warn do
  alias Bolt.Constants
  alias Bolt.Converters
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Footer
  alias Nostrum.Struct.User

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
           {:ok, created_infraction} <- Repo.insert(changeset) do
        %Embed{
          title: "Warning created",
          description:
            "Warned user #{User.mention(member.user)} (ID #{member.user.id}), " <>
              "reason: `#{reason}`",
          color: Constants.color_green(),
          footer: %Footer{
            text: "Infraction created with ID ##{created_infraction.id}"
          }
        }
      else
        "" ->
          %Embed{
            title: "Invalid invocation",
            description: "Must provide a reason to warn the user for.",
            color: Constants.color_red()
          }

        {:error, reason} ->
          %Embed{
            title: "Cannot create warning",
            description: "Unexpected error: #{reason}",
            color: Constants.color_red()
          }
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end
end
