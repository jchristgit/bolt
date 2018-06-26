defmodule Bolt.ModLog.Silencer do
  @moduledoc "An agent that holds guild IDs on which modlogs are silenced."
  use Agent

  @spec start_link(GenServer.options()) :: Agent.on_start()
  def start_link(options) do
    Agent.start_link(fn -> MapSet.new() end, options)
  end

  @spec add(Nostrum.Struct.Snowflake.t()) :: :ok
  def add(guild_id) do
    Agent.update(
      __MODULE__,
      &MapSet.put(&1, guild_id)
    )
  end

  @spec remove(Nostrum.Struct.Snowflake.t()) :: :ok
  def remove(guild_id) do
    Agent.update(
      __MODULE__,
      &MapSet.delete(&1, guild_id)
    )
  end

  @spec is_silenced?(Nostrum.Struct.Snowflake.t()) :: boolean()
  def is_silenced?(guild_id) do
    Agent.get(
      __MODULE__,
      &MapSet.member?(&1, guild_id)
    )
  end
end
