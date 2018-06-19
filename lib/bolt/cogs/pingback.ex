defmodule Bolt.Cogs.Pingback do
  def command(msg, duration) do
    {seconds, _} = Integer.parse(duration)
    unix_timestamp = DateTime.utc_now() |> DateTime.to_unix()
    {:ok, expiry} = (unix_timestamp + seconds) |> DateTime.from_unix()

    Bolt.Events.Handler.create(%Bolt.Schema.Event{
      timestamp: expiry,
      event: "CREATE_MESSAGE",
      data: %{channel_id: msg.channel_id, content: "Ping-pong! Sent from Bolt's event handler."}
    })
  end
end
