defmodule Bolt.Cogs.Tempban do
  alias Bolt.Cogs.Ban
  alias Bolt.Constants
  alias Bolt.Events.Handler
  alias Bolt.Helpers
  alias Bolt.Parsers
  alias Bolt.Repo
  alias Bolt.Schema.Event
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Footer
  alias Nostrum.Struct.User

  def command(msg, [user, duration | reason_list]) do
    response =
      with reason <- Enum.join(reason_list, " "),
           {:ok, user_id, converted_user} <- Ban.into_id(msg.guild_id, user),
           {:ok, expiry} <- Parsers.human_future_date(duration),
           {:ok} <- Api.create_guild_ban(msg.guild_id, user_id, 7),
           {:ok, _event} <-
             Handler.create(%Event{
               timestamp: expiry,
               event: "UNBAN_MEMBER",
               data: %{
                 "guild_id" => msg.guild_id,
                 "user_id" => user_id
               }
             }),
           infraction <- %Infraction{
             type: "tempban",
             guild_id: msg.guild_id,
             user_id: user_id,
             actor_id: msg.author.id,
             reason: if(reason != "", do: reason, else: nil),
             expires_at: expiry
           },
           changeset <- Infraction.changeset(infraction),
           {:ok, created_infraction} <- Repo.insert(changeset) do
        %Embed{
          title: "Temporary ban applied",
          description:
            if(
              converted_user == nil,
              do: "`#{user_id}`",
              else: "#{User.full_name(converted_user)} (`#{user_id}`)"
            ) <> " has been temporary banned until #{Helpers.datetime_to_human(expiry)}",
          color: Constants.color_green(),
          footer: %Footer{
            text: "Infraction created with ID ##{created_infraction.id}"
          }
        }
      else
        {:error, %{status_code: status, message: %{"message" => reason}}} ->
          %Embed{
            title: "Cannot tempban user",
            description: "API Error: #{reason} (status code `#{status}`)",
            color: Constants.color_red()
          }

        {:error, reason} ->
          %Embed{
            title: "Cannot tempban user",
            description: "Error: #{reason}",
            color: Constants.color_red()
          }
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end
end
