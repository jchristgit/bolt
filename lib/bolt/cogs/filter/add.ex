defmodule Bolt.Cogs.Filter.Add do
  @moduledoc false
  @behaviour Nosedrum.Command

  alias Bolt.Commander.Checks
  alias Bolt.{ErrorFormatters, Filter, Repo}
  alias Bolt.Schema.FilteredWord
  alias Nostrum.Api

  @impl true
  def usage, do: ["filter add <token:str...>"]

  @impl true
  def description,
    do: """
    Add a new token to the server's filter.
    Note that without a configured action, a filter being hit won't do anything.
    Check out the `filter action` command to see how to configure actions.
    Tokens must be unique (you can't filter one token multiple times).
    Requires the `MANAGE_GUILD` permission.

    ```rs
    // Filter out messages containing the base invite
    .filter add discord.gg

    // Filter out messages containing "redis is a database"
    .filter add redis is a database
    ```
    """

  @impl true
  def predicates, do: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]

  @impl true
  def command(msg, []) do
    response = "ℹ️ usage: `#{List.first(usage())}`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, token_list) do
    token = Enum.join(token_list, " ")
    token_map = %{guild_id: msg.guild_id, word: token}
    changeset = FilteredWord.changeset(%FilteredWord{}, token_map)

    response =
      case Repo.insert(changeset) do
        {:ok, _struct} ->
          Filter.rebuild(msg.guild_id)
          "👌 token added to filter"

        error ->
          ErrorFormatters.fmt(msg, error)
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
