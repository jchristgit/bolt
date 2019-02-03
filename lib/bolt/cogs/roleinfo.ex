defmodule Bolt.Cogs.RoleInfo do
  @moduledoc false

  @behaviour Nosedrum.Command

  alias Bolt.Commander.Checks
  alias Bolt.{Converters, Helpers}
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.{Embed, Guild}
  alias Nostrum.Struct.Guild.Role
  alias Nostrum.Struct.Snowflake

  @impl true
  def usage, do: ["roleinfo <role:role>"]

  @impl true
  def description,
    do: """
    Show information about the given role.
    The role can be given as either by ID, its name, or a role mention.
    """

  @impl true
  def predicates, do: [&Checks.guild_only/1]

  @impl true
  def parse_args(args), do: Enum.join(args, " ")

  @impl true
  def command(msg, "") do
    response = "🚫 expected role to lookup as sole argument"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, role) do
    case Converters.to_role(msg.guild_id, role, true) do
      {:ok, matching_role} ->
        embed = format_role_info(matching_role, msg.guild_id)
        {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)

      {:error, reason} ->
        response = "🚫 conversion error: #{Helpers.clean_content(reason)}"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end

  @spec format_role_info(Role.t(), Guild.id()) :: Embed.t()
  defp format_role_info(role, guild_id) do
    %Embed{
      title: role.name,
      color: role.color,
      footer: %Embed.Footer{
        text: "Permission bitset: #{Integer.to_string(role.permissions, 2)}"
      },
      fields: [
        %Embed.Field{
          name: "ID",
          value: "#{role.id}",
          inline: true
        },
        %Embed.Field{
          name: "Creation",
          value:
            role.id
            |> Snowflake.creation_time()
            |> Helpers.datetime_to_human(),
          inline: true
        },
        %Embed.Field{
          name: "Color hex",
          value: Integer.to_string(role.color, 16),
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
        },
        %Embed.Field{
          name: "Member count",
          value: count_role_members(role.id, guild_id),
          inline: true
        }
      ]
    }
  end

  @spec count_role_members(Role.id(), Guild.id()) :: String.t()
  defp count_role_members(role_id, guild_id) do
    case GuildCache.get(guild_id) do
      {:ok, guild} ->
        guild.members
        |> Map.values()
        |> Enum.filter(&(role_id in &1.roles))
        |> Enum.count()
        |> Integer.to_string()

      _error ->
        "*unknown, guild not cached*"
    end
  end
end
