defmodule Bolt.Consumer do
  @moduledoc "Consumes events sent by the API gateway."

  alias Bolt.Commander
  use Nostrum.Consumer

  @spec start_link :: Supervisor.on_start()
  def start_link do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  @impl true
  @spec handle_event(Nostrum.Consumer.event()) :: any()
  def handle_event({:MESSAGE_CREATE, {msg}, _ws_state}) do
    Commander.handle_message(msg)
  end

  def handle_event({:MESSAGE_REACTION_ADD, {reaction}, _ws_state}) do
    GenServer.cast(Bolt.Paginator, {:MESSAGE_REACTION_ADD, reaction})
  end

  @impl true
  def handle_event(_event) do
    :noop
  end
end
