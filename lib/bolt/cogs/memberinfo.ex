defmodule Bolt.Cogs.MemberInfo do
  alias Bolt.Constants
  alias Bolt.Converters
  alias Bolt.Helpers
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.Snowflake
  use Timex

  @spec top_role_for(Nostrum.Struct.Snowflake.t(), Member.t()) ::
          Nostrum.Struct.Guild.Role.t() | {:error, String.t()}
  defp top_role_for(guild_id, member) do
    case GuildCache.get(guild_id) do
      {:ok, guild} ->
        guild.roles
        |> Stream.filter(&(&1.id in member.roles))
        |> Enum.max_by(& &1.position, {:error, "*no roles on guild*"})

      {:error, _reason} ->
        {:error, "*unknown, guild not in cache*"}
    end
  end

  @spec format_member_info(Nostrum.Struct.Snowflake.t(), Guild.Member.t()) :: Nostrum.Embed.t()
  defp format_member_info(guild_id, member) do
    join_datetime =
      member.joined_at
      |> DateTime.from_iso8601()
      |> elem(1)

    creation_datetime = Snowflake.creation_time(member.user.id)

    embed = %Embed{
      title: "#{member.user.username}##{member.user.discriminator}",
      fields: [
        %Embed.Field{name: "ID", value: "`#{member.user.id}`", inline: true},
        %Embed.Field{name: "Total roles", value: "#{length(member.roles)}", inline: true},
        %Embed.Field{
          name: "Joined this Guild",
          value: Helpers.datetime_to_human(join_datetime),
          inline: true
        },
        %Embed.Field{
          name: "Joined Discord",
          value: Helpers.datetime_to_human(creation_datetime),
          inline: true
        }
      ],
      thumbnail: %Embed.Thumbnail{url: Helpers.avatar_url(member.user)}
    }

    case top_role_for(guild_id, member) do
      {:error, reason} ->
        Embed.put_field(embed, "Roles", reason)

      role ->
        embed
        |> Embed.put_field(
          "Roles",
          member.roles
          |> Stream.map(&"<@&#{&1}>")
          |> Enum.join(", ")
        )
        |> Embed.put_color(role.color)
    end
  end

  @doc """
  Returns information about yourself.
  """
  def command(name, msg, "") when name in ["minfo", "memberinfo", "member"] do
    embed =
      with guild_id when guild_id != nil <- msg.guild_id,
           {:ok, guild} <- GuildCache.get(msg.guild_id),
           member when member != nil <- Enum.find(guild.members, &(&1.user.id == msg.author.id)) do
        format_member_info(msg.guild_id, member)
      else
        nil ->
          %Embed{
            title: "Cannot display member information",
            description: "Couldn't find you in the guild members. That's a bit odd..",
            color: Constants.color_red()
          }

        {:error, reason} ->
          %Embed{
            title: "Cannot display member information",
            description: "This guild is not in the cache. (#{reason})",
            color: Constants.color_red()
          }
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
  end

  @doc """
  Returns information about the given member.
  The member given can either be an ID, a mention,
  a name#discrim combination, a name, or a nickname.
  """
  def command(name, msg, member) when name in ["minfo", "memberinfo", "member"] do
    embed =
      with guild_id when guild_id != nil <- msg.guild_id,
           {:ok, fetched_member} <- Converters.to_member(guild_id, member) do
        format_member_info(msg.guild_id, fetched_member)
      else
        nil ->
          %Embed{
            title: "Failed to fetch member information",
            description: "This command can only be used on guilds.",
            color: Constants.color_red()
          }

        {:error, reason} ->
          %Embed{
            title: "Failed to fetch member information",
            description: reason,
            color: Constants.color_red()
          }
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
  end
end
