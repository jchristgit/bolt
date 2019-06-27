defmodule Bolt.Cogs.Infraction.General do
  @moduledoc "General utilities used across the infraction subcommands."

  alias Bolt.Humanizer
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Cache.UserCache

  @type_emojis %{
    "note" => "📔",
    "tempmute" => "🔇⏲",
    "forced_nick" => "📛",
    "mute" => "🔇",
    "unmute" => "📢",
    "temprole" => "🎽⏲",
    "warning" => "⚠",
    "kick" => "👢",
    "softban" => "🔨☁",
    "tempban" => "🔨⏲",
    "ban" => "🔨",
    "unban" => "🤝"
  }

  @spec emoji_for_type(String.t()) :: String.t()
  def emoji_for_type(type) do
    Map.get(@type_emojis, type, "?")
  end

  @spec format_user(Nostrum.Struct.Snowflake.t(), Nostrum.Struct.Snowflake.t()) :: String.t()
  def format_user(guild_id, user_id) do
    default_string = "unknown user (`#{user_id}`)"

    case UserCache.get(user_id) do
      {:ok, user} ->
        Humanizer.human_user(user)

      {:error, _reason} ->
        case GuildCache.get(guild_id) do
          {:ok, guild} -> Map.get(guild.members, user_id, default_string)
          {:error, _reason} -> default_string
        end
    end
  end
end
