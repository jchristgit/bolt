defmodule Bolt.USW.Escalator do
  @moduledoc "Tracks members and their punishment 'level'. Escalates it if applicable."

  alias Nostrum.Struct.User
  use Agent

  def start_link(options) do
    Agent.start_link(fn -> %{} end, options)
  end

  @spec bump(User.id(), Calendar.second()) :: {:ok, reference()}
  def bump(user_id, drop_after) do
    Agent.update(
      __MODULE__,
      &Map.get_and_update(
        &1,
        user_id,
        fn level ->
          if level == nil do
            {level, 1}
          else
            {level, level + 1}
          end
        end
      )
    )

    {:ok, _reference} =
      :timer.apply_after(
        drop_after,
        __MODULE__,
        &remove/1,
        [user_id]
      )
  end

  @spec remove(User.id()) :: :ok
  def remove(user_id) do
    Agent.update(
      __MODULE__,
      fn users ->
        Map.delete(users, user_id)
      end
    )
  end
end
