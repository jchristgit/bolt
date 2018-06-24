defmodule Bolt.Events.Handler do
  use GenServer

  ## Client API

  def start_link(options) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  def create(event) do
    alias Bolt.Events.Deserializer
    alias Bolt.Repo
    alias Bolt.Schema
    alias Bolt.Schema.Event
    alias Ecto.Changeset

    changeset = Schema.Event.changeset(%Event{}, event)

    with true <- event.event in Deserializer.valid_events(),
         {:ok, created_event} <- Repo.insert(changeset) do
      GenServer.call(__MODULE__, {:create, created_event})
    else
      false ->
        {:error, "`#{event.type}` is not a valid event type"}

      {:error, %Changeset{} = changeset} ->
        {:error, changeset.errors}

      {:error, _reason} = error ->
        error
    end
  end

  ## Server Callbacks

  @impl true
  def init(:ok) do
    alias Bolt.Repo
    alias Bolt.Schema.Event
    import Ecto.Query, only: [from: 2]

    # Boot a timer for stale events
    timers =
      from(event in Event, select: event)
      |> Repo.all()
      |> Enum.map(fn event ->
        {
          event,
          Process.send_after(
            self(),
            {:expired, event},
            max(
              DateTime.diff(event.timestamp, DateTime.utc_now(), :millisecond),
              0
            )
          )
        }
      end)
      |> Map.new(fn {event, timer} -> {event, timer} end)

    {:ok, timers}
  end

  @impl true
  def handle_call({:create, event}, _from, timers) do
    timers =
      {event,
       Process.send_after(
         self(),
         {:expired, event},
         DateTime.diff(event.timestamp, DateTime.utc_now(), :millisecond)
       )}
      |> (fn {event, timer} -> Map.put(timers, event, timer) end).()

    {:reply, {:ok, event}, timers}
  end

  @impl true
  def handle_info({:expired, event}, timers) do
    alias Bolt.Events.Deserializer
    alias Bolt.Repo

    {:ok, func} = Deserializer.deserialize(event)
    func.()
    timers = Map.delete(timers, event)
    {:ok, _deleted_event} = Repo.delete(event)

    {:noreply, timers}
  end
end
