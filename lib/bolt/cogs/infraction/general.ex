defmodule Bolt.Cogs.Infraction.General do
  @type_emojis %{
    "note" => "📔",
    "tempmute" => "🔇⏲",
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
end
