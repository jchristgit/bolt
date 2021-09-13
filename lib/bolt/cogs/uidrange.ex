defmodule Bolt.Cogs.UidRange do
  @moduledoc false
  @behaviour Nosedrum.Command

  alias Bolt.Constants
  alias Bolt.ErrorFormatters
  alias Bolt.Paginator
  alias Nosedrum.Predicates
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Embed

  @impl true
  def usage, do: ["uidrange <from:snowflake> <to:snowflake>"]

  @impl true
  def description,
    do: """
    Display all users in the given inclusive range of snowflakes.
    Useful for finding accounts on the server that were created
    in a certain period.
    """

  @impl true
  def predicates,
    do: [&Predicates.guild_only/1]

  @impl true
  def command(msg, [from, to]) do
    with {start, ""} <- Integer.parse(from),
         {stop, ""} <- Integer.parse(to) do
      msg.guild_id
      |> find_matches(start, stop)
      |> Enum.sort()
      |> display_matches(msg.channel_id)
    else
      :error ->
        Api.create_message(msg.channel_id, "🚫 invalid snowflakes, sorry")
    end
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `#{usage()}`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  defp find_matches(guild_id, from, to) do
    case GuildCache.get(guild_id) do
      {:ok, guild} ->
        Stream.filter(guild.members, fn {flake, _member} -> flake in from..to end)

      {:error, _why} = result ->
        result
    end
  end

  defp display_matches({:error, why}, where) do
    response = ErrorFormatters.fmt(nil, why)
    {:ok, _msg} = Api.create_message(where, response)
  end

  defp display_matches(matches, where) do
    matches
    |> Stream.chunk_every(10)
    |> Enum.map(&format_chunk/1)
    |> paginate(where)
  end

  defp format_entry({snowflake, member}) do
    "- `#{snowflake}` (#{member.user.username}##{member.user.discriminator})"
  end

  defp format_chunk(chunk) do
    formatted = Stream.map(chunk, &format_entry/1)
    %Embed{description: Enum.join(formatted, "\n")}
  end

  defp paginate(pages, channel_id) do
    base_page = %Embed{
      title: "ID range results",
      color: Constants.color_blue()
    }

    fake_msg = %{channel_id: channel_id}
    Paginator.paginate_over(fake_msg, base_page, pages)
  end
end
