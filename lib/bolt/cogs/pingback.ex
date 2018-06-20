defmodule Bolt.Cogs.Pingback do
  alias Nostrum.Api
  alias Bolt.Parsers

  def command(msg, expiry) do
    case Parsers.human_future_date(expiry) do
      {:ok, date} ->
        Bolt.Events.Handler.create(%Bolt.Schema.Event{
          timestamp: date,
          event: "CREATE_MESSAGE",
          data: %{
            channel_id: msg.channel_id,
            content: "Ping-pong! Sent from Bolt's event handler."
          }
        })

      {:error, reason} ->
        {:ok, _msg} = Api.create_message(msg.channel_id, "failed to parse expiry: #{reason}")
    end
  end
end
