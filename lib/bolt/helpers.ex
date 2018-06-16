defmodule Bolt.Helpers do
  alias Nostrum.Api
  alias Nostrum.Struct.User
  alias Nostrum.Cache.GuildCache
  use Timex

  @doc """
  Returns the Avatar URL for the given user.
  If the user does not have any avatar hash,
  the default avatar for the discriminator is
  returned instead.
  """
  @spec avatar_url(User.t()) :: String.t()
  def avatar_url(user) do
    case user.avatar do
      nil -> "https://cdn.discordapp.com/embed/avatars/#{rem(user.discriminator, 5)}.png"
      hash -> "https://cdn.discordapp.com/avatars/#{user.id}/#{hash}.png"
    end
  end

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
  @spec datetime_to_human(Nostrum.Struct.Snowflake.t()) :: String.t()
  def datetime_to_human(datetime) do
    "#{Timex.format!(datetime, "%d.%m.%y %H:%M", :strftime)} (#{Timex.from_now(datetime)})"
  end

  @doc "Try to return a member of the given guild ID with the given author ID."
  @spec get_member(Nostrum.Struct.Snowflake.t(), Nostrum.Struct.Snowflake.t()) ::
          {:ok, Nostrum.Struct.Guild.Member.t()} | {:error, String.t()}
  def get_member(guild_id, author_id) do
    case GuildCache.get(guild_id) do
      {:ok, guild} ->
        case Enum.find(
               guild.members,
               {:error, "There is no member with ID #{author_id} in this guild"},
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
            {:error,
             "This guild is not in the cache, and no member with the ID #{author_id} could be found"}
        end
    end
  end

  @spec find_role([Nostrum.Struct.Guild.Role.t()], [Nostrum.Struct.Guild.Role.t()]) ::
          {:ok, Nostrum.Struct.Guild.Role.t()} | {:error, String.t()}
  defp find_role(guild_roles, member_roles) do
    role_match =
      guild_roles
      |> Stream.filter(&(&1.id in member_roles))
      |> Enum.max_by(& &1.position, {:error, "no roles on guild"})

    case role_match do
      {:error, reason} -> {:error, reason}
      role -> {:ok, role}
    end
  end

  @doc "Returns the top role for the given member ID on the given guild, representative for permissions on the given guild ID."
  @spec top_role_for(Nostrum.Struct.Snowflake.t(), Nostrum.Struct.Snowflake.t()) ::
          {:ok, Nostrum.Struct.Guild.Role.t()} | {:error, String.t()}
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

  @doc "Replace `@everyone` and `@here` mentions with their harmless variants"
  @spec clean_content(String.t()) :: String.t()
  def clean_content(content) do
    content
    |> String.replace("@everyone", "@\u200Beveryone")
    |> String.replace("@here", "@\u200Bhere")
  end
end
