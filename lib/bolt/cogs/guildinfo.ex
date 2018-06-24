defmodule Bolt.Cogs.GuildInfo do
  alias Bolt.Constants
  alias Bolt.Helpers
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Snowflake
  use Timex

  @spec format_guild_info(Guild.t()) :: Embed.t()
  defp format_guild_info(guild) do
    info_embed = %Embed{
      title: guild.name,
      color: Constants.color_blue(),
      fields: [
        %Embed.Field{
          name: "Statistics",
          value: """
          Channels: #{
            if guild.channels != nil,
              do: length(guild.channels),
              else: "*unknown, guild not in cache*"
          }
          Emojis: #{length(guild.emojis)}
          Roles: #{length(guild.roles)}
          Members: #{Map.get(guild, :member_count, "*unknown, guild not in cache*")}
          """,
          inline: true
        },
        %Embed.Field{
          name: "Owner",
          value: "<@#{guild.owner_id}> (`#{guild.owner_id}`)",
          inline: true
        },
        %Embed.Field{
          name: "ID",
          value: "#{guild.id}",
          inline: true
        },
        %Embed.Field{
          name: "Creation date",
          value: Snowflake.creation_time(guild.id) |> Helpers.datetime_to_human(),
          inline: true
        },
        %Embed.Field{
          name: "Voice region",
          value: guild.region,
          inline: true
        },
        %Embed.Field{
          name: "Features",
          value:
            (fn ->
               features =
                 guild.features
                 |> Stream.map(&"`#{&1}`")
                 |> Enum.join(", ")

               case features do
                 "" -> "none"
                 value -> value
               end
             end).(),
          inline: true
        }
      ]
    }

    if guild.icon != nil do
      info_embed
      |> Embed.put_thumbnail(Guild.icon_url(guild, "png"))
    end
  end

  @spec fetch_and_build(Nostrum.Struct.Snowflake.t(), String.t()) :: String.t()
  defp fetch_and_build(guild_id, on_not_found) do
    with {:ok, guild} <- GuildCache.get(guild_id) do
      format_guild_info(guild)
    else
      {:error, _reason} ->
        case Api.get_guild(guild_id) do
          {:ok, guild} ->
            format_guild_info(guild)

          {:error, _reason} ->
            %Embed{
              title: "Failed to fetch guild information",
              description:
                "#{on_not_found} was not found in the cache nor " <>
                  "could any information be fetched from the API.",
              color: Constants.color_red()
            }
        end
    end
  end

  @doc """
  Display information about the guild that
  this command is invoked on.
  """
  def command(msg, []) do
    embed = fetch_and_build(msg.guild_id, "This guild")
    {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
  end

  @doc "Display information about the given guild ID"
  def command(msg, [guild_id]) do
    case Nostrum.Struct.Snowflake.cast(guild_id) do
      {:ok, snowflake} when snowflake != nil ->
        embed = fetch_and_build(snowflake, "A guild with ID `#{snowflake}`")
        {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)

      _ ->
        response = "🚫 `#{Helpers.clean_content(guild_id)}` is not a valid guild ID"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end
end
