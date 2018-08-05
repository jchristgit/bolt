defmodule Bolt.Filter do
  @moduledoc "A `GenServer` which performs message filtering."

  alias Bolt.Schema.FilteredWord
  alias Bolt.Repo
  alias Nostrum.Struct.Message
  require Logger
  use GenServer

  ## Client functions

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  @spec check_for_matches(Message.t()) :: MapSet.t()
  def check_for_matches(msg) do
    GenServer.call(__MODULE__, {:search, msg.guild_id, msg.content})
  end

  ## Callbacks

  @impl true
  def init(:ok) do
    # Grab all words and build up an internal map of them.
    state =
      FilteredWord
      |> Repo.all()
      |> Enum.reduce(%{}, fn word_row, acc ->
        {_get, state} =
          Map.get_and_update(
            acc,
            word_row.guild_id,
            &{&1, if(&1 == nil, do: [word_row.word], else: [word_row.word | &1])}
          )

        state
      end)
      |> Enum.reduce(%{}, fn {guild_id, words}, acc ->
        Map.put(acc, guild_id, AhoCorasick.new(words))
      end)

    Logger.debug(fn ->
      total_ids = state |> Map.keys() |> length()
      total_words = state |> Map.values() |> Enum.count()
      "Built aho-corasick graphs, total of #{total_words} words for #{total_ids} guilds."
    end)

    {:ok, state}
  end

  @impl true
  def handle_call({:search, guild_id, content}, _from, guild_graphs) do
    case Map.get(guild_graphs, guild_id) do
      nil ->
        {:reply, MapSet.new(), guild_graphs}

      guild_graph ->
        matches = AhoCorasick.search(guild_graph, content)
        {:reply, matches, guild_graphs}
    end
  end

  @impl true
  def handle_call(:state, _from, guild_graphs) do
    {:reply, guild_graphs, guild_graphs}
  end
end
