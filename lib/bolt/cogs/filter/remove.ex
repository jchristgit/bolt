defmodule Bolt.Cogs.Filter.Remove do
  @moduledoc false
  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.{ErrorFormatters, Filter, Repo}
  alias Bolt.Schema.FilteredWord
  alias Nostrum.Api

  @impl true
  def usage, do: ["filter remove <token:str...>"]

  @impl true
  def description,
    do: """
    Removes the given `token` from the filter.
    No-op if the `token` is not filtered currently.
    Requires the `MANAGE_GUILD` permission.
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

    response =
      with row when row != nil <- Repo.get_by(FilteredWord, guild_id: msg.guild_id, word: token),
           {:ok, _deleted_row} <- Repo.delete(row) do
        Filter.rebuild(msg.guild_id)
        "👌 will no longer filter that token"
      else
        nil -> "🚫 the given token is not filtered"
        error -> ErrorFormatters.fmt(msg, error)
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
