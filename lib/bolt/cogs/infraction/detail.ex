defmodule Bolt.Cogs.Infraction.Detail do
  alias Bolt.Cogs.Infraction.General
  alias Bolt.Constants
  alias Bolt.Helpers
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Cache.UserCache
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Field
  alias Nostrum.Struct.Embed.Footer
  alias Nostrum.Struct.Message
  alias Nostrum.Struct.User

  @spec get_user(pos_integer()) :: {:ok, User.t()} | {:error, String.t()}
  defp get_user(user_id) do
    case UserCache.get(user_id) do
      {:ok, _user} = result ->
        result

      {:error, _reason} ->
        case Api.get_user(user_id) do
          {:ok, _user} = result -> result
          {:error, _reason} -> {:error, "unknown user (`#{user_id}`)"}
        end
    end
  end

  @spec get_response(Message.t(), pos_integer) :: Embed.t()
  def get_response(msg, id) do
    case Repo.get_by(Infraction, id: id, guild_id: msg.guild_id) do
      nil ->
        %Embed{
          title: "Failed to look up infraction ##{id}",
          description: "No infraction with the given ID found. Does it exist on this guild?",
          color: Constants.color_red()
        }

      infraction ->
        %Embed{
          title: "Infraction ##{id}",
          color: Constants.color_blue(),
          fields: [
            %Field{
              name: "User",
              value:
                (fn ->
                   case get_user(infraction.user_id) do
                     {:ok, user} -> "#{User.full_name(user)} (`#{user.id}`)"
                     {:error, user_string} -> user_string
                   end
                 end).(),
              inline: true
            },
            %Field{
              name: "Type",
              value:
                "#{General.emoji_for_type(infraction.type)} #{String.capitalize(infraction.type)}",
              inline: true
            },
            %Field{
              name: "Creation",
              value: Helpers.datetime_to_human(infraction.inserted_at),
              inline: true
            },
            %Field{
              name: "Modification",
              value:
                (fn ->
                   if DateTime.diff(infraction.inserted_at, infraction.updated_at, :seconds) < 1 do
                     "*never*"
                   else
                     Helpers.datetime_to_human(infraction.updated_at)
                   end
                 end).(),
              inline: true
            },
            %Field{
              name: "Reason",
              value:
                (fn ->
                   case infraction.reason do
                     nil -> "*not specified*"
                     "" -> "*empty reason specified*"
                     reason -> reason
                   end
                 end).(),
              inline: true
            },
            %Field{
              name: "Expiry",
              value:
                (fn ->
                   case infraction.expires_at do
                     nil -> "*not set*"
                     expiry -> Helpers.datetime_to_human(expiry)
                   end
                 end).(),
              inline: true
            }
          ],
          footer:
            (fn ->
               case get_user(infraction.actor_id) do
                 {:ok, user} ->
                   %Footer{
                     icon_url: User.avatar_url(user),
                     text: "authored by #{User.full_name(user)} (#{user.id})"
                   }

                 {:error, user_string} ->
                   %Footer{
                     text: "authored by #{user_string}"
                   }
               end
             end).()
        }
    end
  end
end
