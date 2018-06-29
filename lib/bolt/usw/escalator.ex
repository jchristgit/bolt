defmodule Bolt.USW.Escalator do
  @moduledoc "Tracks members and their punishment 'level'. Escalates it if applicable."

  alias Nostrum.Struct.User
  require Logger
  use Agent

  def start_link(options) do
    Agent.start_link(fn -> %{} end, options)
  end

  @spec bump(User.id(), Calendar.millisecond()) :: {:ok, reference()}
  def bump(user_id, expire_after) do
    Agent.update(
      __MODULE__,
      &(Map.get_and_update(
          &1,
          user_id,
          fn settings ->
            {:ok, timer_reference} =
              :timer.apply_after(
                expire_after,
                __MODULE__,
                :drop,
                [user_id]
              )

            case settings do
              {level, timer} ->
                {:ok, :cancel} = :timer.cancel(timer)

                if level == nil do
                  {settings, {1, timer_reference}}
                else
                  {settings, {level + 1, timer_reference}}
                end

              nil ->
                {nil, {1, timer_reference}}
            end
          end
        )
        |> elem(1))
    )
  end

  @spec level_for(User.id()) :: pos_integer()
  def level_for(user_id) do
    Agent.get(
      __MODULE__,
      fn levels ->
        {level, _tref} = Map.get(levels, user_id, {0, nil})
        level
      end
    )
  end

  @spec drop(User.id()) :: :ok
  def drop(user_id) do
    Agent.update(__MODULE__, &Map.delete(&1, user_id))
  end
end
