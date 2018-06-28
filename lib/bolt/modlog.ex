defmodule Bolt.ModLog do
  @moduledoc "Distributes gateway or bot events to the appropriate channels."

  alias Bolt.ModLog.Silencer
  alias Bolt.Repo
  alias Bolt.Schema.ModLogConfig
  alias Nostrum.Api
  alias Nostrum.Error.ApiError
  alias Nostrum.Struct.{Embed, Message, Snowflake}

  @event_emoji %{
    "AUTOMOD" => "🛡",
    "BOT_UPDATE" => "📄",
    "CONFIG_UPDATE" => "📃",
    "INFRACTION_CREATE" => "📟",
    "INFRACTION_UPDATE" => "🖋",
    "INFRACTION_EVENTS" => "⏲",
    "GUILD_MEMBER_ADD" => "📥",
    "GUILD_MEMBER_REMOVE" => "📤",
    "MESSAGE_EDIT" => "🖊",
    "MESSAGE_DELETE" => "🗑"
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
          Snowflake.t(),
          String.t(),
          String.t() | Embed.t()
        ) :: on_emit()
  def emit(guild_id, event, content) do
    with %ModLogConfig{channel_id: channel_id} <-
           Repo.get_by(ModLogConfig, guild_id: guild_id, event: event),
         false <- Silencer.is_silenced?(guild_id) do
      event_emoji = Map.get(@event_emoji, event, "?")

      case content do
        %Embed{} = log_embed ->
          log_embed = Map.put(log_embed, :title, "#{event_emoji} `#{event}`")
          Api.create_message(channel_id, embed: log_embed)

        _string ->
          Api.create_message(channel_id, "#{event_emoji} #{content}")
      end
    else
      _err -> :noop
    end
  end
end
