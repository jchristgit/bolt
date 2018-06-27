defmodule Bolt.USW.Deduplicator do
  @moduledoc "Prevents multiple punishments to apply for the same user in a short amount of time."

  use Agent

  def start_link(options) do
    Agent.start_link(fn -> MapSet.new() end, options)
  end

  @spec add(Nostrum.Struct.User.id(), non_neg_integer()) :: {:ok, reference()}
  def add(user_id, expiry_seconds) do
    Agent.update(
      __MODULE__,
      fn users ->
        MapSet.put(users, user_id)
      end
    )

    {:ok, _reference} =
      :timer.apply_after(
        expiry_seconds * 1000,
        __MODULE__,
        &remove/1,
        [user_id]
      )
  end

  @spec remove(Nostrum.Struct.User.id()) :: :ok
  def remove(user_id) do
    Agent.update(
      __MODULE__,
      fn users ->
        MapSet.delete(users, user_id)
      end
    )
  end

  @spec contains?(Nostrum.Struct.User.id()) :: boolean()
  def contains?(user_id) do
    Agent.get(
      __MODULE__,
      fn users ->
        MapSet.member?(users, user_id)
      end
    )
  end
end
