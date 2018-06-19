defmodule Bolt.Events.Deserializer do
  def deserialize(%{event: "CREATE_MESSAGE", data: %{"channel_id" => channel_id, "content" => content}}) do
    alias Nostrum.Api

    func = fn -> Api.create_message(channel_id, content) end
    {:ok, func}
  end
end
