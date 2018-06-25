defmodule Bolt.ModLog do
  @moduledoc "Distributes gateway or bot events to the appropriate channels."

  alias Bolt.Repo
  alias Bolt.Schema.ModLogConfig
  alias Nostrum.Api

  @event_emoji %{
    "AUTOMOD" => "🛡",
    "BOT_UPDATE" => "📄",
    "CONFIG_UPDATE" => "📃",
    "INFRACTION_CREATE" => "📟",
    "INFRACTION_UPDATE" => "🖋",
    "INFRACTION_EVENTS" => "⏲"
  }

  @doc """
  Emits the given `content` to the mod log
  of the given Guild ID. If the guild does not
  have any log configured with the given event,
  `:noop` is returned. Otherwise, the result of the
  `Nostrum.Api.create_message/2` call is returned.
  """
  @spec emit(
    Nostrum.Struct.Snowflake.t(),
    String.t(),
    String.t()
  ) :: {:ok, Nostrum.Struct.Message.t()} | {:error, Nostrum.Error.ApiError.t()} | :noop
  def emit(guild_id, event, content) do
    case Repo.get_by(ModLogConfig, guild_id: guild_id, event: event) do
      nil ->
        :noop

      %ModLogConfig{channel_id: channel_id} ->
        event_emoji = Map.get(@event_emoji, event, "?")
        Api.create_message(channel_id, "#{event_emoji} #{content}")
    end
  end
end
