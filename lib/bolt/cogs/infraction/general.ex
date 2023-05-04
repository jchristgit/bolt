defmodule Bolt.Cogs.Infraction.General do
  @moduledoc "General utilities used across the infraction subcommands."

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
    "unban" => "🤝",
    "timeout" => "⏱️"
  }

  @spec emoji_for_type(String.t()) :: String.t()
  def emoji_for_type(type) do
    Map.get(@type_emojis, type, "?")
  end
end
