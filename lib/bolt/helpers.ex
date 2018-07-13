defmodule Bolt.Helpers do
  @moduledoc "Various helpers used throughout the bot."

  alias Bolt.Converters
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Guild.{Member, Role}
  alias Nostrum.Struct.User
  require Logger
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
          Guild.id(),
          User.id()
        ) :: {:ok, Member.t()} | {:error, String.t()}
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
          [Role.t()],
          [Snowflake.id()]
        ) :: {:ok, Role.t()} | {:error, String.t()}
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
          Guild.id(),
          User.id()
        ) :: {:ok, Role.t()} | {:error, String.t()}
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
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Replace `@everyone` and `@here` mentions with their harmless variants
  """
  @spec clean_content(String.t()) :: String.t()
  def clean_content(content) do
    content
    |> String.replace("@everyone", "@\u200Beveryone")
    |> String.replace("@here", "@\u200Bhere")
  end

  @doc "Convert text into either a raw snowflake or a snowflake + member."
  @spec into_id(Guild.id(), String.t()) ::
          {:ok, User.id(), User.t() | nil}
          | {:error, String.t()}
  def into_id(guild_id, text) do
    case Integer.parse(text) do
      {value, ""} ->
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

  @doc "Checks that `actor_id`'s top role is above `target_id`s top role on `guild_id`."
  @spec is_above(Guild.id(), User.id(), User.id()) :: {:ok, true | false} | {:error, String.t()}
  def is_above(guild_id, actor_id, target_id) do
    with {:ok, actor_top_role} <- top_role_for(guild_id, actor_id) do
      case top_role_for(guild_id, target_id) do
        {:ok, target_top_role} ->
          {:ok, actor_top_role.position > target_top_role.position}

        # If the author passed all checks and got around to invoke the command,
        # happens to have a single role, and the target member does not have any
        # roles, then the author is always above the member in the hierarchy.
        # This does not take guild ownership into account.
        {:error, "no roles on member"} ->
          {:ok, true}

        # If the target user is no longer on the guild, then the actor is surely above them
        # in the role hierarchy. This is usually the case with bans.
        {:error, "there is no member with ID " <> _remainder} ->
          {:ok, true}

        {:error, _reason} = error ->
          error
      end
    else
      _err ->
        {:error,
         "🚫 you need to be above the target" <>
           " user in the role hierarchy to run that," <> " that, but you don't have any roles"}
    end
  end
end
