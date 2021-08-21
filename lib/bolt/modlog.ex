defmodule Bolt.ModLog do
  @moduledoc "Distributes gateway or bot events to the appropriate channels."

  alias Bolt.Repo
  alias Bolt.Schema.ModLogConfig
  alias Nostrum.Api
  alias Nostrum.Error.ApiError
  alias Nostrum.Struct.{Embed, Message}

  @event_emoji %{
    "AUTOMOD" => "🛡",
    "BOT_UPDATE" => "📄",
    "CHANNEL_CREATE" => "#⃣",
    "CHANNEL_DELETE" => "🗑",
    "CHANNEL_UPDATE" => "♻",
    "CONFIG_UPDATE" => "⚙",
    "ERROR" => "❌",
    "GUILD_BAN_ADD" => "🔨",
    "GUILD_BAN_REMOVE" => "🤝",
    "GUILD_MEMBER_ADD" => "📥",
    "GUILD_MEMBER_REMOVE" => "📤",
    "GUILD_MEMBER_UPDATE" => "♻",
    "GUILD_ROLE_DELETE" => "🚮",
    "GUILD_ROLE_UPDATE" => "♻",
    "INFRACTION_CREATE" => "📟",
    "INFRACTION_EVENTS" => "⏲",
    "INFRACTION_UPDATE" => "🖋",
    "MESSAGE_CLEAN" => "🗑",
    "MESSAGE_DELETE" => "🗑",
    "MESSAGE_EDIT" => "🖊"
  }

  @typedoc "The return type used by `emit`. Set as a type for convenience."
  @type on_emit :: {:ok, Message.t()} | {:error, ApiError.t()} | :noop

  @doc """
  Emits the given `content` to the mod log
  of the given Guild ID. If the guild does not
  have any log configured with the given event,
  `:noop` is returned. Otherwise, the result of the
  `Nostrum.Api.create_message/2` call is returned.
  """
  @spec emit(
          Guild.id(),
          String.t(),
          String.t(),
          Keyword.t()
        ) :: on_emit()
  def emit(guild_id, event, content, opts \\ []) do
    case Repo.get_by(ModLogConfig, guild_id: guild_id, event: event) do
      %ModLogConfig{channel_id: channel_id} ->
        event_emoji = Map.get(@event_emoji, event, "?")

        opts =
          if content != "" do
            Keyword.put(opts, :content, "#{event_emoji} #{content}")
          else
            opts
          end

        Api.create_message(channel_id, opts)

      _other ->
        :noop
    end
  end

  @spec emit_embed(Guild.id(), String.t(), Embed.t()) :: on_emit()
  def emit_embed(guild_id, event, embed) do
    event_emoji = Map.get(@event_emoji, event, "?")
    embed = Map.put(embed, :title, "#{event_emoji} `#{event}`")
    emit(guild_id, event, "", embed: embed)
  end
end
