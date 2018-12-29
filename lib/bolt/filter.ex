defmodule Bolt.Filter do
  @moduledoc "A `GenServer` which performs message filtering."

  alias Bolt.Repo
  alias Bolt.Schema.FilteredWord
  alias Nostrum.Struct.{Guild, Message}
  import Ecto.Query, only: [from: 2]
  require Logger
  use GenServer

  ## Client functions

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  @spec check_for_matches(Message.t()) :: [
          {start_index :: non_neg_integer(), end_index :: non_neg_integer(),
           pattern :: charlist()}
        ]
  def check_for_matches(msg) do
    GenServer.call(__MODULE__, {:search, msg.guild_id, msg.content})
  end

  @spec rebuild(Guild.id()) :: :ok
  def rebuild(guild_id), do: GenServer.cast(__MODULE__, {:rebuild, guild_id})

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
        charlist_words = Enum.map(words, &String.to_charlist/1)
        Map.put(acc, guild_id, :aho_corasick.build_tree(charlist_words))
      end)

    Logger.debug(fn ->
      total_ids = state |> Map.keys() |> length()
      total_words = state |> Map.values() |> Enum.count()
      "Built aho-corasick structures, total of #{total_words} words for #{total_ids} guilds."
    end)

    {:ok, state}
  end

  @impl true
  def handle_call({:search, guild_id, content}, _from, guild_trees) do
    case Map.get(guild_trees, guild_id) do
      nil ->
        {:reply, [], guild_trees}

      guild_tree ->
        matches = :aho_corasick.match(String.to_charlist(content), guild_tree)
        {:reply, matches, guild_trees}
    end
  end

  @impl true
  def handle_call(:state, _from, guild_trees) do
    {:reply, guild_trees, guild_trees}
  end

  @impl true
  def handle_cast({:rebuild, guild_id}, guild_trees) do
    query =
      from(filtered_word in FilteredWord,
        where: filtered_word.guild_id == ^guild_id,
        select: filtered_word.word
      )

    case Repo.all(query) do
      # If there are no longer any words, drop the entry as it'd be empty otherwise.
      [] ->
        Logger.debug(fn ->
          "Filter graph rebuild found 0 words for guild `#{guild_id}`, dropping graph entry"
        end)

        {:noreply, Map.delete(guild_trees, guild_id)}

      words ->
        Logger.debug(fn ->
          "Rebuilding filter graph for guild `#{guild_id}`."
        end)

        new_tree = :aho_corasick.build_tree(Enum.map(words, &String.to_charlist/1))
        updated_state = Map.put(guild_trees, guild_id, new_tree)
        {:noreply, updated_state}
    end
  end
end
