defmodule Bolt.Events.Handler do
  @moduledoc """
  Handles scheduled infractions persisted to the `infractions` table.
  Infraction IDs are mapped to timers internally.
  """

  alias Bolt.ErrorFormatters
  alias Bolt.Events.Deserializer
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  import Ecto.Query, only: [from: 2]
  use GenServer

  ## Client API

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  @spec create(%{
          type: String.t(),
          data: %{
            required(String.t()) => any()
          }
        }) ::
          {:ok, Infraction.t()}
          | {:error, String.t()}
  def create(infraction_map) do
    changeset = Infraction.changeset(%Infraction{}, infraction_map)

    case Repo.insert(changeset) do
      {:ok, created_infraction} ->
        if created_infraction.expires_at != nil do
          GenServer.call(__MODULE__, {:create, created_infraction})
        else
          {:ok, created_infraction}
        end

      {:error, _reason} = error ->
        response = ErrorFormatters.fmt(nil, error)
        {:error, response}
    end
  end

  @spec update(Infraction.t(), map()) :: {:ok, Infraction} | {:error, any()}
  def update(infraction, changes_map) do
    changeset = Infraction.changeset(infraction, changes_map)

    with {:ok, _timer} <- GenServer.call(__MODULE__, {:drop_timer, infraction.id}),
         {:ok, updated_infraction} <- Repo.update(changeset) do
      if updated_infraction.expires_at != nil and updated_infraction.active do
        GenServer.call(
          __MODULE__,
          {:create, updated_infraction}
        )
      end

      {:ok, updated_infraction}
    else
      error -> error
    end
  end

  ## Server Callbacks

  @impl true
  def init(:ok) do
    # Start a timer for stale events
    query =
      from(
        infr in Infraction,
        where: infr.active and not is_nil(infr.expires_at),
        select: infr
      )

    timers =
      query
      |> Repo.all()
      |> Enum.map(fn infraction ->
        {
          infraction,
          Process.send_after(
            self(),
            {:expired, infraction},
            max(
              DateTime.diff(infraction.expires_at, DateTime.utc_now(), :millisecond),
              0
            )
          )
        }
      end)
      |> Map.new(fn {infraction, timer} -> {infraction.id, timer} end)

    {:ok, timers}
  end

  @impl true
  def handle_call({:create, infraction}, _from, timers) do
    delta = DateTime.diff(infraction.expires_at, DateTime.utc_now(), :millisecond)
    expiry_ms = max(delta, 0)
    timer = Process.send_after(self(), {:expired, infraction}, expiry_ms)
    updated_timers = Map.put(timers, infraction.id, timer)
    {:reply, {:ok, infraction}, updated_timers}
  end

  @impl true
  def handle_call({:drop_timer, infraction_id}, _from, timers) do
    with {:ok, timer} <- Map.fetch(timers, infraction_id),
         to_expiry when is_integer(to_expiry) <- Process.cancel_timer(timer) do
      {:reply, {:ok, timer}, Map.delete(timers, infraction_id)}
    else
      :error ->
        {:reply,
         {:error,
          "infraction `#{infraction_id}` is not registered" <>
            " in the event handler, did it already expire?"}, timers}

      _error ->
        {:reply, {:error, "could not cancel the timer properly"}, timers}
    end
  end

  @impl true
  def handle_info({:expired, infraction}, timers) do
    alias Bolt.Events.Deserializer
    alias Bolt.Repo

    {:ok, func} = Deserializer.deserialize(infraction)

    # Update the infraction before handling it to prevent race conditions.
    changeset = Infraction.changeset(infraction, %{active: false})
    {:ok, _updated_infraction} = Repo.update(changeset)

    func.()
    timers = Map.delete(timers, infraction.id)

    {:noreply, timers}
  end
end
