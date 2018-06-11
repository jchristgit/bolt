defmodule Bolt.Consumer do
  alias Nostrum.Api
  use Nostrum.Consumer

  def start_link do
    IO.puts "starting consumer"
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, {msg}, _ws_state}) do
    IO.puts "handling message event"
    case msg.content do
      "ping!" ->
        Api.create_message(msg.channel_id, "I copy and pasted this code")
      _ -> :ignore
    end
    :noop
  end

  def handle_event(event) do
    IO.puts "handling unknown event"
    IO.inspect event
    :noop
  end
end
