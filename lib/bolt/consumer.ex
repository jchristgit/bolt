defmodule Bolt.Consumer do
  use Nostrum.Consumer
  alias Bolt.Cogs
  alias Bolt.Commander


  def start_link() do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, {msg}, _ws_state}) do
    Commander.handle_message(msg)
  end

  def handle_event(_event) do
    :noop
  end
end
