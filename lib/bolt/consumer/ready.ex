defmodule Bolt.Consumer.Ready do
  @moduledoc "Handles the `READY` event."

  alias Bolt.BotLog
  alias Nostrum.Api

  @spec handle(map()) :: :ok
  def handle(data) do
    BotLog.emit("⚡ Logged in and ready, seeing `#{length(data.guilds)}` guilds.")
    :ok = Api.update_status(:online, "you | .help", 3)
  end
end
