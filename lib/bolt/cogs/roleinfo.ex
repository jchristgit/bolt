defmodule Bolt.Cogs.RoleInfo do
  alias Bolt.Constants
  alias Bolt.Converters
  alias Bolt.Helpers
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Snowflake

  @spec format_role_info(Nostrum.Struct.Guild.Role.t()) :: Embed.t()
  defp format_role_info(role) do
    %Embed{
      title: role.name,
      color: role.color,
      fields: [
        %Embed.Field{
          name: "ID",
          value: "#{role.id}",
          inline: true
        },
        %Embed.Field{
          name: "Creation",
          value: Snowflake.creation_time(role.id) |> Helpers.datetime_to_human(),
          inline: true
        },
        %Embed.Field{
          name: "Permission bitset",
          value: "#{role.permissions}",
          inline: true
        },
        %Embed.Field{
          name: "Color value",
          value: "#{role.color}",
          inline: true
        },
        %Embed.Field{
          name: "Mentionable",
          value: Helpers.bool_to_human(role.mentionable),
          inline: true
        },
        %Embed.Field{
          name: "Position",
          value: "#{role.position}",
          inline: true
        }
      ]
    }
  end

  def command(msg, "") do
    response = %Embed{
      title: "Failed to fetch role information",
      description: "You need to add the role you want to retrieve information about as an argument.",
      color: Constants.color_red
    }
    {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
  end

  def command(msg, role) do
    embed =
      if msg.guild_id != nil do
        case Converters.to_role(msg.guild_id, role, true) do
          {:ok, matching_role} ->
            format_role_info(matching_role)

          {:error, reason} ->
            %Embed{
              title: "Failed to fetch role information",
              description: "Could not convert the given argument to a role: #{reason}",
              color: Constants.color_red()
            }
        end
      else
        %Embed{
          title: "Failed to fetch role information",
          description: "This command can only be used on guilds.",
          color: Constants.color_red()
        }
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
  end
end
