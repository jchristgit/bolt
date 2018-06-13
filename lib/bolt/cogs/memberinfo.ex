defmodule Bolt.Cogs.MemberInfo do
  alias Bolt.Converters
  alias Nostrum.Api

  @doc """
  Returns information about yourself.
  """
  def command(name, msg, []) when name in ["minfo", "memberinfo", "member"] do
  end

  @doc """
  Returns information about the given member.
  The member given can either be an ID, a mention,
  a name#discrim combination, a name, or a nickname.
  """
  def command(name, msg, [member]) when name in ["minfo", "memberinfo", "member"] do
    content =
      case Converters.member(msg.guild_id, member) do
        {:ok, fetched_member} -> "user #{fetched_member}"
        {:error, reason} -> "nope - #{reason}"
        res -> "#{inspect(res)}??"
      end

    Api.create_message(msg.channel_id, content)
  end
end
