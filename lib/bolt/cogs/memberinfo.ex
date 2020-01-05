defmodule Bolt.Cogs.MemberInfo do
  @moduledoc false

  @behaviour Nosedrum.Command

  alias Bolt.{Converters, Helpers}
  alias Nosedrum.Predicates
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Snowflake
  alias Nostrum.Struct.{Embed, User}

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

  @impl true
  def usage, do: ["memberinfo [member:member]"]

  @impl true
  def description,
    do: """
    Look up information about the given `member`.
    When no argument is given, shows information about yourself.
    """

  @impl true
  def predicates, do: [&Predicates.guild_only/1]

  @impl true
  def parse_args(args), do: Enum.join(args, " ")

  @impl true
  def command(msg, "") do
    with {:ok, guild} <- GuildCache.get(msg.guild_id),
         member when member != nil <- Map.get(guild.members, msg.author.id) do
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

  def command(msg, maybe_member) do
    case Converters.to_member(msg.guild_id, maybe_member) do
      {:ok, fetched_member} ->
        embed = format_member_info(msg.guild_id, fetched_member)
        {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)

      {:error, reason} ->
        response = "❌ couldn't fetch member information: #{reason}"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end
end
