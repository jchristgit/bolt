defmodule Bolt.Converters do
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache

  @doc """
  Convert a Discord user mention to an ID.
  This also works if the given string is just the ID.

  ## Examples

    iex> user_mention_to_id("<@10101010>")
    10101010
    iex> user_mention_to_id("<@!101010>")
    101010
    iex> user_mention_to_id("91203")
    91203
    iex> user_mention_to_id("not valid")
    :error
  """
  @spec user_mention_to_id(String.t()) :: {:ok, pos_integer()} | {:error, String.t()}
  def user_mention_to_id(text) do
    maybe_id =
      text
      |> String.trim_leading("<@")
      |> String.trim_leading("!")
      |> String.trim_trailing(">")

    case Integer.parse(maybe_id) do
      {value, _remainder} -> {:ok, value}
      :error -> {:error, "not a valid ID"}
    end
  end

  @doc """
  Convert a given string in the form name#discrim
  to parts {name, discrim} parts. If no "#" can be
  found in the string, returns `:error`.
  Additionally, this function verifies that the
  discriminator is between 0001 and 9999 (the range
  of valid discriminators on Discord).

  ## Examples

    iex> text_to_name_and_discrim("hello#0312")
    {"hello", "0312"}
    iex> text_to_name_and_discrim("marc#4215")
    {"marc", "4215"}
    iex> text_to_name_and_discrim("name")
    :error
    iex> text_to_name_and_discrim("joe#109231")
    :error
  """
  @spec text_to_name_and_discrim(String.t()) :: {String.t(), String.t()} | :error
  def text_to_name_and_discrim(text) do
    match_result = :binary.match(String.reverse(text), "#")

    if match_result != :nomatch do
      {index, _length} = match_result
      index = String.length(text) - index
      {name, discrim} = String.split_at(text, index - 1)
      discrim = String.trim_leading(discrim, "#")

      with {value, _remainder} when value in 0001..9999 <- Integer.parse(discrim) do
        {name, discrim}
      else
        _err -> :error
      end
    else
      :error
    end
  end

  @doc """
  Try looking up a mentioned member
  in the given text. The lookup of the member
  works by trying to lookup by the following:
  - ID
  - mention
  - name#discrim
  - name
  - nickname
  """
  @spec member(Nostrum.Struct.Snowflake.t(), String.t()) ::
          {:ok, Nostrum.Struct.Member.t()} | {:error, String.t()}
  def member(guild_id, text) do
    with {:ok, user_id} <- user_mention_to_id(text),
         {:ok, fetched_member} <- Api.get_guild_member(guild_id, user_id) do
      {:ok, fetched_member}
    else
      {:error, %{message: %{message: reason}}} ->
        {:error, reason}

      {:error, _why} ->
        case GuildCache.get(guild_id) do
          {:ok, %{members: members}} ->
            case text_to_name_and_discrim(text) do
              {name, discrim} ->
                case Enum.find(
                       members,
                       &(&1.user.username == name and &1.user.discriminator == discrim)
                     ) do
                  nil -> {:error, "There is no member named `#{name}##{discrim}` on this Guild."}
                  member -> {:ok, member}
                end

              :error ->
                case Enum.find(members, &(&1.user.username == text)) do
                  nil ->
                    case Enum.find(members, &(&1.nick == text)) do
                      nil -> {:error, "Failed to find any member matching `#{text}` on this guild."}
                      member -> {:ok, member}
                    end

                  member ->
                    {:ok, member}
                end
            end

          {:error, _reason} ->
            {:error, "This Guild is not in the cache, cannot find any members"}
        end
    end
  end
end
