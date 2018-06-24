defmodule Bolt.Cogs.Roles do
  alias Bolt.Constants
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Guild.Role

  @spec get_role_list(Nostrum.Struct.Snowflake.t()) :: {:ok, [Role.t()]} | {:error, String.t()}
  defp get_role_list(guild_id) do
    case GuildCache.get(guild_id) do
      {:ok, guild} ->
        {:ok, guild.roles}

      {:error, _reason} ->
        case Api.get_guild_roles(guild_id) do
          {:ok, roles} ->
            {:ok, roles}

          {:error, _api_error} ->
            {:error, "Couldn't look up guild from either the cache or the API"}
        end
    end
  end

  def command(msg, "") do
    embed =
      case get_role_list(msg.guild_id) do
        {:ok, roles} ->
          %Embed{
            title: "All roles on this guild",
            description: roles |> Stream.map(&Role.mention/1) |> Enum.join(", "),
            color: Constants.color_blue()
          }

        {:error, reason} ->
          %Embed{
            title: "Failed to fetch guild roles",
            description: reason,
            color: Constants.color_red()
          }
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
  end

  def command(msg, name) do
    embed =
      case get_role_list(msg.guild_id) do
        {:ok, roles} ->
          %Embed{
            title: "Roles matching `#{name}` on this guild (case-insensitive)",
            description:
              roles
              |> Stream.filter(&String.contains?(String.downcase(&1.name), String.downcase(name)))
              |> Stream.map(&Role.mention/1)
              |> Enum.join(", "),
            color: Constants.color_blue()
          }

        {:error, reason} ->
          %Embed{
            title: "Failed to fetch guild roles",
            description: reason,
            color: Constants.color_red()
          }
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
  end
end
