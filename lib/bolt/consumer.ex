defmodule Bolt.Consumer do
  alias Bolt.Commands
  alias Nostrum.Api
  use Nostrum.Consumer

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, {msg}, _ws_state}) do
    Commands.handle(msg)
    :noop
  end

  def handle_event(event) do
    IO.inspect event
    :noop
  end
end
