defmodule Bolt.Cogs.MemberInfo do
  @moduledoc false

  alias Bolt.Converters
  alias Bolt.Helpers
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Snowflake
  alias Nostrum.Struct.User
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
      thumbnail: %Embed.Thumbnail{url: User.avatar_url(member.user)}
    }

    case Helpers.top_role_for(guild_id, member.user.id) do
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
    with {:ok, guild} <- GuildCache.get(msg.guild_id),
         member when member != nil <- Enum.find(guild.members, &(&1.user.id == msg.author.id)) do
      embed = format_member_info(msg.guild_id, member)
      {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
    else
      nil ->
        response = "❌ failed to find you in this guild's members - that's a bit weird"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)

      {:error, reason} ->
        response = "❌ error: #{Helpers.clean_content(reason)}"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end

  @doc """
  Returns information about the given member.
  The member given can either be an ID, a mention,
  a name#discrim combination, a name, or a nickname.
  """
  def command(msg, member) do
    with {:ok, fetched_member} <- Converters.to_member(msg.guild_id, member) do
      embed = format_member_info(msg.guild_id, fetched_member)
      {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
    else
      {:error, reason} ->
        response = "❌ couldn't fetch member information: #{Helpers.clean_content(reason)}"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end
end
