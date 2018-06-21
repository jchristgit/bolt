defmodule Bolt.Cogs.Ban do
  alias Bolt.Constants
  alias Bolt.Converters
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Footer
  alias Nostrum.Struct.User

  @spec into_id(Nostrum.Struct.Snowflake.t(), String.t()) ::
          {:ok, Nostrum.Struct.Snowflake.t(), Nostrum.Struct.User.t() | nil}
          | {:error, String.t()}
  defp into_id(guild_id, text) do
    case Integer.parse(text) do
      {value, _} ->
        {:ok, value, nil}

      :error ->
        case Converters.to_member(guild_id, text) do
          {:ok, member} -> {:ok, member.user.id, member.user}
          {:error, _} = error -> error
        end
    end
  end

  def command(msg, [user | reason_list]) do
    response =
      with reason <- Enum.join(reason_list, " "),
           {:ok, user_id, converted_user} <- into_id(msg.guild_id, user),
           {:ok} <- Api.create_guild_ban(msg.guild_id, user_id, 7),
           infraction <- %Infraction{
             type: "ban",
             guild_id: msg.guild_id,
             user_id: user_id,
             actor_id: msg.author.id,
             reason: if(reason != "", do: reason, else: nil)
           },
           changeset <- Infraction.changeset(infraction),
           {:ok, created_infraction} <- Repo.insert(changeset) do
        %Embed{
          title: "Ban successful",
          description: """
          Banned #{
            if converted_user != nil,
              do: "#{User.full_name(converted_user)} (`#{converted_user.id}`)",
              else: user_id
          }#{if reason != nil, do: ", reason: `#{reason}`"}
          """,
          color: Constants.color_green(),
          footer: %Footer{
            text: "Infraction created with ID ##{created_infraction.id}"
          }
        }
      else
        {:error, %{status_code: status, message: %{"message" => reason}}} ->
          %Embed{
            title: "Cannot ban user",
            description: "API Error: #{reason} (status code `#{status}`)",
            color: Constants.color_red()
          }

        {:error, reason} ->
          %Embed{
            title: "Cannot ban user",
            description: "Error: #{reason}",
            color: Constants.color_red()
          }
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end
end
