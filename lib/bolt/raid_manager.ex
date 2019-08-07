defmodule Bolt.RaidManager do
  @moduledoc """
  Manages raid-specific guild state, backing the `raidctl` commands.

  More specifically, this GenServer tracks which members are selected
  for the current raid manager batch per guild. Entries are expired
  automatically.
  """

  # :timer.minutes(30)
  @drop_after :timer.seconds(30)

  alias Nostrum.Struct.Guild
  use GenServer

  @doc """
  Add the given `members` to the selected members of the given guild.
  """
  @spec add(Guild.id(), Enum.t()) :: :ok
  @spec add(GenServer.server(), Guild.id(), Enum.t()) :: :ok
  def add(server \\ __MODULE__, guild_id, members) do
    GenServer.call(server, {:add, guild_id, members})
  end

  @doc """
  Remove the given guild from the internal state.

  No-op if the guild is not present.
  """
  @spec drop(Guild.id()) :: :ok
  @spec drop(GenServer.server(), Guild.id()) :: :ok
  def drop(server \\ __MODULE__, guild_id) do
    GenServer.call(server, {:drop, guild_id})
  end

  @doc """
  Return all selections for the given guild, or an empty `t:MapSet.t/0`
  if no members are recorded or selected.
  """
  @spec get(Guild.id()) :: MapSet.t()
  @spec get(GenServer.server(), Guild.id()) :: MapSet.t()
  def get(server \\ __MODULE__, guild_id) do
    GenServer.call(server, {:get, guild_id})
  end

  def start_link(options) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:add, guild_id, members}, _from, state) do
    if not Map.has_key?(state, guild_id) do
      {:ok, _timer} = :timer.apply_after(@drop_after, Bolt.RaidManager, :drop, [guild_id])
    end

    new_set = MapSet.new(members)
    updated_state = Map.update(state, guild_id, new_set, &MapSet.union(&1, new_set))
    {:reply, :ok, updated_state}
  end

  @impl true
  def handle_call({:get, guild_id}, _from, state) do
    value = Map.get_lazy(state, guild_id, &MapSet.new/0)
    {:reply, value, state}
  end

  @impl true
  def handle_call({:drop, guild_id}, _from, state) do
    {:reply, :ok, Map.delete(state, guild_id)}
  end
end
