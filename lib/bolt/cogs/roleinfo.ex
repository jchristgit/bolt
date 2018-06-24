defmodule Bolt.Cogs.RoleInfo do
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
    response = "🚫 expected role to lookup as sole argument"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, role) do
    case Converters.to_role(msg.guild_id, role, true) do
      {:ok, matching_role} ->
        embed = format_role_info(matching_role)
        {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)

      {:error, reason} ->
        response = "🚫 conversion error: #{Helpers.clean_content(reason)}"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end
end
