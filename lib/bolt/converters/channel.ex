defmodule Bolt.Converters.Channel do
  alias Bolt.Helpers
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache

  @doc """
  Convert a Discord channel mention to an ID.
  This also works if the given string is just the ID.

  ## Examples

    iex> channel_mention_to_id("<#10101010>")
    {:ok, 10101010}
    iex> channel_mention_to_id("<#101010>")
    {:ok, 101010}
    iex> channel_mention_to_id("91203")
    {:ok, 91203}
    iex> channel_mention_to_id("not valid")
    {:error, "not a valid channel ID"}
  """
  @spec channel_mention_to_id(String.t()) :: {:ok, pos_integer()} | {:error, String.t()}
  def channel_mention_to_id(text) do
    maybe_id =
      text
      |> String.trim_leading("<#")
      |> String.trim_trailing(">")

    case Integer.parse(maybe_id) do
      {value, _remainder} -> {:ok, value}
      :error -> {:error, "not a valid channel ID"}
    end
  end

  # Attempt to find a channel within the given `channels`
  # matching the given `text`.
  # The lookup strategy is as follows:
  # - Channel ID
  # - Channel mention
  # - Channel name
  defp find_channel(channels, text) do
    case channel_mention_to_id(text) do
      {:ok, id} ->
        Enum.find(
          channels,
          {:error, "No channel with ID `#{id}` found on this guild"},
          &(&1.id == id)
        )

      {:error, _reason} ->
        Enum.find(
          channels,
          {:error, "No channel named `#{Helpers.clean_content(text)}` found on this guild"},
          &(&1.name == text)
        )
    end
  end

  @doc "Find a channel on the given `guild_id` matching `text`."
  @spec channel(Nostrum.Struct.Snowflake.t(), String.t()) ::
          {:ok, Nostrum.Struct.Guild.Channel.t()} | {:error, String.t()}
  def channel(guild_id, text) do
    case GuildCache.get(guild_id) do
      {:ok, guild} ->
        find_channel(guild.channels, text)

      {:error, _reason} ->
        case Api.get_guild_channels(guild_id) do
          {:ok, channels} ->
            find_channel(channels, text)

          {:error, _reason} ->
            {:error, "This guild is not in the cache, nor could it be fetched from the API."}
        end
    end
  end
end
