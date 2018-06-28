defmodule Bolt.Consumer.Ready do
  @moduledoc "Handles the `READY` event."

  alias Bolt.BotLog

  @spec handle(map()) :: :ok
  def handle(data) do
    BotLog.emit("⚡ Logged in and ready, seeing `#{length(data.guilds)}` guilds.")
  end
end
