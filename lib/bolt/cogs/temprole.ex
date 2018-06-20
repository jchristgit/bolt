defmodule Bolt.Cogs.Temprole do
  alias Bolt.Constants
  alias Bolt.Converters
  alias Bolt.Helpers
  alias Bolt.Parsers
  alias Bolt.Events.Handler
  alias Bolt.Schema.Event
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Footer
  alias Nostrum.Struct.Guild.Role
  alias Nostrum.Struct.User

  def command(msg, [user, role, duration | reason_list]) do
    response =
      with _reason <- Enum.join(reason_list, " "),
           {:ok, member} <- Converters.to_member(msg.guild_id, user),
           {:ok, role} <- Converters.to_role(msg.guild_id, role),
           {:ok, expiry} <- Parsers.human_future_date(duration),
           {:ok} <-
             Api.modify_guild_member(
               msg.guild_id,
               member.user.id,
               roles: Enum.uniq(member.roles ++ [role.id])
             ),
           {:ok, _event} <-
             Handler.create(%Event{
               timestamp: expiry,
               event: "REMOVE_ROLE",
               data: %{
                 guild_id: msg.guild_id,
                 user_id: member.user.id,
                 role_id: role.id
               }
             }) do
        %Embed{
          title: "Temporary role applied",
          description:
            "Attached the role #{Role.mention(role)} to " <>
              "#{User.mention(member.user)} until #{Helpers.datetime_to_human(expiry)}",
          color: Constants.color_green(),
          footer: %Footer{
            text: "Authored by #{User.full_name(msg.author)} (#{msg.author.id})",
            icon_url: User.avatar_url(msg.author)
          }
        }
      else
        {:error, %{message: %{"message" => reason}, status_code: status}} ->
          %Embed{
            title: "Failed to apply temporary role",
            description: "API Error: #{reason} (status #{status})",
            color: Constants.color_red()
          }

        {:error, %{message: :timeout}} ->
          %Embed{
            title: "Failed to apply temporary role",
            description: "The Discord API did not respond with anything in time. Perhaps retry?",
            color: Constants.color_red()
          }

        {:error, reason} ->
          %Embed{
            title: "Failed to apply temporary role",
            description: "Error: #{reason}",
            color: Constants.color_red()
          }
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end

  def command(msg, incorrect_args) do
    response = %Embed{
      title: "Incorrect command invocation",
      description: """
      Failed to match
        `<user:member> <role:role> <duration:duration> [reason:str]`
      from given arguments '#{incorrect_args}'.
      """,
      color: Constants.color_red(),
      footer: %Footer{
        text: "Check `help temprole` for more information."
      }
    }

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end
end
