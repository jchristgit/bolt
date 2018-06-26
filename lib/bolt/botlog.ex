defmodule Bolt.BotLog do
  @moduledoc "A bot log, used for logging bot events to the bot administrator."
  alias Nostrum.Api

  @spec emit(String.t()) :: {:ok, Nostrum.Struct.Message.t()} | :noop
  def emit(content) do
    case Application.fetch_env(:bolt, :botlog_channel) do
      {:ok, channel_id} when channel_id != nil ->
        {actual_id, _} = Integer.parse(channel_id)
        {:ok, _msg} = Api.create_message(actual_id, content)

      _ ->
        :noop
    end
  end
end
