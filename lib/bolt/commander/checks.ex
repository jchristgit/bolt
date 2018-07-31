defmodule Bolt.Commander.Checks do
  @moduledoc "Implements various checks used by commands."

  alias Bolt.{BotLog, Helpers}
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.{Message, User}
  use Bitwise

  @doc """
  A function that checks whether
  the given message was sent on a
  Gulid. Note that messages retrieved
  via REST do not have the `guild_id`
  attribute set, and thus, will not
  be detected as guild messages properly.
  """
  @spec guild_only(Message.t()) :: {:ok, Message.t()} | {:error, String.t()}
  def guild_only(msg) do
    case msg.guild_id do
      nil ->
        {:error, "this command can only be used on guilds"}

      _guild_id ->
        {:ok, msg}
    end
  end

  # Checks if the author of `message` has
  # the permissions specified in `to_check`.
  # If yes, returns `{:ok, msg}`
  # If no, returns `{:error, embed}`
  # If an error occured, returns `{:error, embed}`
  @spec has_permission?(Message.t(), atom) :: {:ok, Message.t()} | {:error, String.t()}
  defp has_permission?(msg, permission) do
    with {:ok, guild} <- GuildCache.get(msg.guild_id),
         member when member != nil <- Enum.find(guild.members, &(&1.user.id === msg.author.id)) do
      if permission in Member.guild_permissions(member, guild) do
        {:ok, msg}
      else
        permission_string =
          permission
          |> Atom.to_string()
          |> String.upcase()

        {:error, "🚫 you need the `#{permission_string}` permission to do that"}
      end
    else
      {:error, _reason} -> {:error, "❌ this guild is not in the cache, can't check perms"}
      nil -> {:error, "❌ you're not in the guild member cache, can't check perms"}
    end
  end

  @doc "Checks that the message author has the `MANAGE_ROLES` permission."
  @spec can_manage_roles?(Message.t()) :: {:ok, Message.t()} | {:error, String.t()}
  def can_manage_roles?(msg) do
    has_permission?(msg, :manage_roles)
  end

  @doc "Checks that the message author has the `MANAGE_MESSSAGES` permission."
  @spec can_manage_messages?(Message.t()) :: {:ok, Message.t()} | {:error, String.t()}
  def can_manage_messages?(msg) do
    has_permission?(msg, :manage_messages)
  end

  @doc "Checks that the message author has the `KICK_MEMBERS` permission."
  @spec can_kick_members?(Message.t()) :: {:ok, Message.t()} | {:error, String.t()}
  def can_kick_members?(msg) do
    has_permission?(msg, :kick_members)
  end

  @doc "Checks that the message author has the `BAN_MEMBERS` permission."
  @spec can_ban_members?(Message.t()) :: {:ok, Message.t()} | {:error, String.t()}
  def can_ban_members?(msg) do
    has_permission?(msg, :ban_members)
  end

  @doc "Checks that the message author has the `MANAGE_GUILD` permission."
  @spec can_manage_guild?(Message.t()) :: {:ok, Message.t()} | {:error, String.t()}
  def can_manage_guild?(msg) do
    has_permission?(msg, :manage_guild)
  end

  @doc "Checks that the message author has the `MANAGE_NICKNAMES` permission."
  @spec can_manage_nicknames?(Message.t()) :: {:ok, Message.t()} | {:error, String.t()}
  def can_manage_nicknames?(msg) do
    has_permission?(msg, :manage_nicknames)
  end

  @doc "Checks that the message author is in the superuser list."
  @spec is_superuser?(Message.t()) :: {:ok, Message.t()} | {:error, String.t()}
  def is_superuser?(msg) do
    if msg.author.id in Application.fetch_env!(:bolt, :superusers) do
      BotLog.emit(
        "🔓 #{User.full_name(msg.author)} (`#{msg.author.id}`) passed the root user check" <>
          " and is about to invoke `#{Helpers.clean_content(msg.content)}`" <>
          " in channel `#{msg.channel_id}`"
      )

      {:ok, msg}
    else
      BotLog.emit(
        "🔒#{User.full_name(msg.author)} (`#{msg.author.id}`) attempted using the root-only" <>
          " command `#{Helpers.clean_content(msg.content)}` in channel `#{msg.channel_id}`" <>
          if(
            msg.guild_id != nil,
            do: " on guild ID `#{msg.guild_id}`",
            else: ", which is a direct message channel"
          )
      )

      {
        :error,
        "🚫 #{User.full_name(msg.author)} is not in the sudoers file." <>
          " This incident will be reported."
      }
    end
  end
end
