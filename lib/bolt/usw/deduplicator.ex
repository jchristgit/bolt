defmodule Bolt.USW.Deduplicator do
  @moduledoc "Prevents multiple punishments to apply for the same user in a short amount of time."

  alias Nostrum.Struct.User
  require Logger
  use Agent

  def start_link(options) do
    Agent.start_link(fn -> MapSet.new() end, options)
  end

  @spec add(pid(), User.id(), Calendar.millisecond()) :: {:ok, reference()}
  def add(deduplicator \\ __MODULE__, user_id, expire_after) do
    Agent.update(
      deduplicator,
      fn users ->
        MapSet.put(users, user_id)
      end
    )

    Logger.debug(fn ->
      "Added #{user_id} to the USW deduplicator, expiry after #{expire_after}ms"
    end)

    {:ok, _reference} =
      :timer.apply_after(
        expire_after,
        __MODULE__,
        :remove,
        [deduplicator, user_id]
      )
  end

  @spec remove(pid(), User.id()) :: :ok
  def remove(deduplicator \\ __MODULE__, user_id) do
    Logger.debug(fn -> "Removing #{user_id} from the USW deduplicator" end)

    Agent.update(
      deduplicator,
      fn users ->
        MapSet.delete(users, user_id)
      end
    )
  end

  @spec contains?(pid(), User.id()) :: boolean()
  def contains?(deduplicator \\ __MODULE__, user_id) do
    Agent.get(
      deduplicator,
      fn users ->
        MapSet.member?(users, user_id)
      end
    )
  end
end
