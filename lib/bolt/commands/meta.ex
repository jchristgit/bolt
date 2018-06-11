defmodule Bolt.Commands.Meta do
  use Alchemy.Cogs
  alias Alchemy.{Cache, Client, Guild, Embed}
  require Alchemy.Embed
  alias Bolt.Constants

  @spec get_member(Alchemy.Cache.snowflake(), Alchemy.Cache.snowflake()) ::
          {:ok, Alchemy.User} | {:err, :not_found}
  defp get_member(guild_id, user_id) do
    case Cache.member(guild_id, user_id) do
      {:ok, member} ->
        member

      {:error, _reason} ->
        case Client.get_member(guild_id, user_id) do
          {:ok, member} -> member
          {:error, _} -> {:error, :not_found}
        end
    end
  end

  @spec format_guild_info(Alchemy.Guild.t()) :: Alchemy.Embed.t()
  defp format_guild_info(guild) do
    info_embed =
      %Embed{
        title: guild.name,
        color: Constants.color_blue()
      }
      |> Embed.field("Total roles", length(guild.roles) |> to_string, inline: true)
      |> Embed.field("Total emojis", length(guild.emojis) |> to_string, inline: true)
      |> Embed.field(
        "Total members",
        Map.get(guild, :member_count, "*unknown, guild not in cache*"),
        inline: true
      )
      |> Embed.thumbnail(Guild.icon_url(guild))

    with {:ok, owner_id} when owner_id != nil <- Map.fetch(guild, :owner_id),
         {:ok, owner} <- get_member(guild.id, owner_id) do
      info_embed =
        Embed.field(
          info_embed,
          "Owner",
          "#{owner.user.username}##{owner.user.discriminator} (<@#{owner.user.id}>)",
          inline: true
        )
    else
      {:error, :not_found} ->
        info_embed = Embed.field(info_embed, "Owner", "<@#{guild.owner_id}>", inline: true)

      _err ->
        info_embed = Embed.field(info_embed, "Owner", "*unknown, failed to fetch*")
    end

    with {:ok, creation_iso8601} when creation_iso8601 != nil <- Map.fetch(guild, :joined_at),
         {:ok, creation_stamp} <- DateTime.from_iso8601(creation_iso8601) do
      info_embed
      |> Embed.timestamp(creation_stamp)
      |> Embed.footer(text: "Creation date")
    else
      _err -> info_embed
    end
  end

  @doc """
  Display basic information about the guild.

  Some data may not be available in the cache.
  Although Bolt tries its best to obtain the missing data
  from the API, sometimes things will not work as expected
  and some data might be omitted from the default layout.
  """
  Cogs.def guildinfo do
    case Cogs.guild() do
      {:ok, guild} ->
        {:ok, _msg} =
          format_guild_info(guild)
          |> Embed.send()

      {:error, _reason} ->
        with {:ok, guild_id} <- Cogs.guild_id(),
             {:ok, guild} <- Client.get_guild(guild_id) do
          {:ok, _msg} =
            format_guild_info(guild)
            |> Embed.send()
        else
          _error ->
            {:ok, _msg} =
              %Embed{
                title: "Failed to fetch guild information",
                description:
                  "This guild is not in my cache, nor can I fetch it " <>
                    "from the API. That's a bit weird..."
              }
              |> Embed.send()
        end
    end
  end
end
