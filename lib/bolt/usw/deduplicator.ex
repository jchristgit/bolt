defmodule Bolt.USW.Deduplicator do
  @moduledoc "Prevents multiple punishments to apply for the same user in a short amount of time."

  alias Nostrum.Struct.User
  require Logger
  use Agent

  def start_link(options) do
    Agent.start_link(fn -> MapSet.new() end, options)
  end

  @spec add(User.id(), Calendar.second()) :: {:ok, reference()}
  def add(user_id, expiry_seconds) do
    Agent.update(
      __MODULE__,
      fn users ->
        MapSet.put(users, user_id)
      end
    )

    Logger.debug(fn ->
      "Added #{user_id} to the USW deduplicator, expiry after #{expiry_seconds}s"
    end)

    {:ok, _reference} =
      :timer.apply_after(
        expiry_seconds * 1000,
        __MODULE__,
        :remove,
        [user_id]
      )
  end

  @spec remove(User.id()) :: :ok
  def remove(user_id) do
    Logger.debug(fn -> "Removing #{user_id} from the USW deduplicator" end)

    Agent.update(
      __MODULE__,
      fn users ->
        MapSet.delete(users, user_id)
      end
    )
  end

  @spec contains?(User.id()) :: boolean()
  def contains?(user_id) do
    Agent.get(
      __MODULE__,
      fn users ->
        MapSet.member?(users, user_id)
      end
    )
  end
end
