defmodule Bolt.Cogs.MemberInfo do
  alias Bolt.Constants
  alias Bolt.Converters
  alias Bolt.Helpers
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Snowflake
  use Timex

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

    case Helpers.top_role_for(guild_id, member) do
      {:error, reason} ->
        Embed.put_field(embed, "Roles", "*#{reason}*")

      {:ok, role} ->
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
  def command(msg, "") do
    embed =
      with {:ok, guild} <- GuildCache.get(msg.guild_id),
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
  def command(msg, member) do
    embed =
      with {:ok, fetched_member} <- Converters.to_member(msg.guild_id, member) do
        format_member_info(msg.guild_id, fetched_member)
      else
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
