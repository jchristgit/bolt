defmodule Bolt.Cogs.GuildInfo do
  alias Bolt.Constants
  alias Bolt.Helpers
  alias Nostrum.Api
  alias Nostrum.Guild
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Snowflake
  use Timex

  @guild_only_embed %Embed{
    title: "Failed to fetch guild information",
    description: "This command needs to be invoked on a Guild.",
    color: Constants.color_red()
  }

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
          value:
            (fn ->
               if guild.joined_at != nil do
                 Snowflake.creation_time(guild.id)
                 |> Helpers.datetime_to_human()
               else
                 "*unknown, guild not in cache*"
               end
             end).(),
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
      |> Embed.put_thumbnail("https://cdn.discordapp.com/icons/#{guild.id}/#{guild.icon}.png")
    end
  end

  @doc """
  Display information about the guild that
  this command is invoked on.
  """
  def command(name, msg, _args) when name in ["ginfo", "guildinfo", "guild"] do
    embed =
      with guild_id when guild_id != nil <- msg.guild_id,
           {:ok, guild} <- GuildCache.get(guild_id) do
        format_guild_info(guild)
      else
        nil ->
          @guild_only_embed

        {:error, _reason} ->
          case Api.get_guild(msg.guild_id) do
            {:ok, guild} ->
              format_guild_info(guild)

            {:error, _reason} ->
              @guild_only_embed
              |> Embed.put_description(
                "This Guild was not found in the cache nor " <>
                  "could any information be fetched from the API."
              )
          end
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
  end
end
