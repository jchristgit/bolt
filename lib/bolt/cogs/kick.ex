defmodule Bolt.Cogs.Kick do
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
      with reason <- Enum.join(reason_list, " "),
           {:ok, member} <- Converters.to_member(msg.guild_id, user),
           {:ok} <- Api.remove_guild_member(msg.guild_id, member.user.id),
           infraction <- %{
             type: "kick",
             guild_id: msg.guild_id,
             user_id: member.user.id,
             actor_id: msg.author.id,
             reason: if(reason != "", do: reason, else: nil)
           },
           changeset <- Infraction.changeset(%Infraction{}, infraction),
           {:ok, created_infraction} <- Repo.insert(changeset) do
        "👌 kicked"

        %Embed{
          title: "Kick successful",
          description:
            (fn ->
               if reason == "" do
                 "Kicked #{User.full_name(member.user)} (`#{member.user.id}`)."
               else
                 "Kicked #{User.full_name(member.user)} (`#{member.user.id}`), reason: `#{reason}`"
               end
             end).(),
          color: Constants.color_green(),
          footer: %Footer{
            text: "Infraction reated with ID ##{created_infraction.id}"
          }
        }
      else
        {:error, %{status_code: status, message: %{"message" => reason}}} ->
          %Embed{
            title: "Cannot kick user",
            description: "API Error: #{reason} (status code `#{status}`)",
            color: Constants.color_red()
          }

        {:error, reason} ->
          %Embed{
            title: "Cannot kick user",
            description: "Error: #{reason}",
            color: Constants.color_red()
          }
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end
end
