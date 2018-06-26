defmodule Bolt.Helpers do
  @moduledoc "Various helpers used throughout the bot."

  alias Bolt.Converters
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  use Timex

  @doc """
  Convert a boolean value to the
  "human" string equivalent.

  ## Examples

    iex> Helpers.bool_to_human(true)
    "yes"
    iex> Helpers.bool_to_human(false)
    "no"
  """
  @spec bool_to_human(boolean) :: String.t()
  def bool_to_human(value) do
    case value do
      true -> "yes"
      false -> "no"
    end
  end

  @doc """
  Converts a valid datetime to a
  human-readable string in the form
  "dd.mm.yy hh:mm (n [seconds/minutes/hours/days/weeks/months/years] ago)"
  """
  @spec datetime_to_human(DateTime.t()) :: String.t()
  def datetime_to_human(datetime) do
    "#{Timex.format!(datetime, "%d.%m.%y %H:%M", :strftime)} (#{Timex.from_now(datetime)})"
  end

  @doc "Try to return a member of the given guild ID with the given author ID."
  @spec get_member(
          Nostrum.Struct.Snowflake.t(),
          Nostrum.Struct.Snowflake.t()
        ) :: {:ok, Nostrum.Struct.Guild.Member.t()} | {:error, String.t()}
  def get_member(guild_id, author_id) do
    case GuildCache.get(guild_id) do
      {:ok, guild} ->
        case Enum.find(
               guild.members,
               {
                 :error,
                 "there is no member with ID #{author_id} in this guild"
               },
               &(&1.user.id == author_id)
             ) do
          {:error, reason} -> {:error, reason}
          member -> {:ok, member}
        end

      {:error, _reason} ->
        case Api.get_guild_member(guild_id, author_id) do
          {:ok, member} ->
            {:ok, member}

          {:error, _why} ->
            {
              :error,
              "This guild is not in the cache, and no " <>
                "member with the ID #{author_id} could be found"
            }
        end
    end
  end

  @spec find_role(
          [Nostrum.Struct.Guild.Role.t()],
          [Nostrum.Struct.Guild.Role.t()]
        ) :: {:ok, Nostrum.Struct.Guild.Role.t()} | {:error, String.t()}
  defp find_role(guild_roles, member_roles) do
    role_match =
      guild_roles
      |> Stream.filter(&(&1.id in member_roles))
      |> Enum.max_by(& &1.position, fn -> {:error, "no roles on member"} end)

    case role_match do
      {:error, _reason} = error -> error
      role -> {:ok, role}
    end
  end

  @doc "Returns the top role for the given member ID on the given guild, representative for permissions on the given guild ID."
  @spec top_role_for(
          Nostrum.Struct.Snowflake.t(),
          Nostrum.Struct.Snowflake.t()
        ) :: {:ok, Nostrum.Struct.Guild.Role.t()} | {:error, String.t()}
  def top_role_for(guild_id, member_id) do
    with {:ok, member} <- get_member(guild_id, member_id) do
      case GuildCache.get(guild_id) do
        {:ok, guild} ->
          find_role(guild.roles, member.roles)

        {:error, _reason} ->
          case Api.get_guild_roles(guild_id) do
            {:ok, roles} ->
              find_role(roles, member.roles)

            {:error, _} ->
              {:error, "guild was not in the cache, nor could it be fetched from the API"}
          end
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Replace `@everyone` and `@here` mentions with their harmless variants
  """
  @spec clean_content(String.t()) :: String.t()
  def clean_content(content) do
    content
    |> String.replace("@", "@\u200B")
  end

  @doc "Convert text into either a raw snowflake or a snowflake + member."
  @spec into_id(Nostrum.Struct.Snowflake.t(), String.t()) ::
          {:ok, Nostrum.Struct.Snowflake.t(), Nostrum.Struct.User.t() | nil}
          | {:error, String.t()}
  def into_id(guild_id, text) do
    case Integer.parse(text) do
      {value, _} ->
        {:ok, value, nil}

      :error ->
        case Converters.to_member(guild_id, text) do
          {:ok, member} -> {:ok, member.user.id, member.user}
          {:error, _} = error -> error
        end
    end
  end

  @doc """
  Given a changeset with errors, format them nicely for humans to understand.
  Returns a list of strings with the errors, in the form '{key} {error}'.
  """
  @spec format_changeset_errors(Ecto.Changeset.t()) :: [String.t()]
  def format_changeset_errors(changeset) do
    alias Ecto.Changeset

    error_map =
      changeset
      |> Changeset.traverse_errors(fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)

    error_map
    |> Map.keys()
    |> Enum.map(&"#{&1} #{error_map[&1]}")
  end
end
