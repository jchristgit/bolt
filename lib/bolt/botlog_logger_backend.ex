defmodule Bolt.BotLogLoggerBackend do
  @moduledoc "Emits error log events to the bot log."

  alias Bolt.BotLog

  @behaviour :gen_event
  @default_level :error
  @prefix "🧻 "

  # State is level.
  @impl true
  def init(__MODULE__) do
    {:ok, @default_level}
  end

  def init({__MODULE__, opts}) do
    {:ok, Keyword.get(opts, :level, @default_level)}
  end

  @impl true
  def handle_event(
        {level, group_leader, {Logger, message, _timestamp, metadata}},
        configured_level
      )
      when node(group_leader) == node() and level == configured_level do
    app = Keyword.get(metadata, :application)
    content = "#{@prefix}**#{app}**: ``#{message}``"
    BotLog.emit(content)
    {:ok, level}
  end

  @impl true
  def handle_event({_level, _group_leader, {Logger, _message, _timestamp, _metadata}}, state) do
    {:ok, state}
  end

  @impl true
  def handle_event(:flush, state) do
    # Events are emitted immediately on reception.
    {:ok, state}
  end

  @impl true
  def handle_call({:configure, options}, level) do
    new_level = Keyword.get(options, :level, level)
    {:ok, :ok, new_level}
  end
end
