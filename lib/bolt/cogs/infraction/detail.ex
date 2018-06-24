defmodule Bolt.Cogs.Infraction.Detail do
  alias Bolt.Cogs.Infraction.General
  alias Bolt.Constants
  alias Bolt.Helpers
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Field
  alias Nostrum.Struct.Embed.Footer
  alias Nostrum.Struct.Message

  @spec add_specific_fields(Embed.t(), Infraction) :: Embed.t()
  defp add_specific_fields(embed, %Infraction{type: "temprole", data: data}) do
    new_field = %Field{
      name: "Added role",
      value: "<@&#{data["role_id"]}>",
      inline: true
    }

    {_, embed} =
      Map.get_and_update(embed, :fields, fn fields ->
        {fields, fields ++ [new_field]}
      end)

    embed
  end

  defp add_specific_fields(embed, _) do
    embed
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
              value: General.format_user(infraction.user_id),
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
                   if DateTime.diff(infraction.inserted_at, infraction.updated_at, :seconds) == 0 do
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
          footer: %Footer{
            text: "authored by #{General.format_user(infraction.actor_id)}"
          }
        }
        |> add_specific_fields(infraction)
    end
  end
end
