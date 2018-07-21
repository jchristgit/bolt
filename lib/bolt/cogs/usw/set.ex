defmodule Bolt.Cogs.USW.Set do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.{ErrorFormatters, Helpers, Repo}
  alias Bolt.Schema.USWFilterConfig
  alias Nostrum.Api

  @impl true
  def usage, do: ["usw set <filter:str> <count:int> <interval:int>"]

  @impl true
  def description,
    do: """
    Sets the given `filter` to allow `count` objects to pass through within `interval` seconds.

    Existing filters:
    • `BURST`: Allows `count` messages by the same author within `interval` seconds.

    For example, to allow 5 messages by the same user within 7 seconds (using the `BURST` filter), one would use `usw set BURST 5 7`.

    Requires the `MANAGE_GUILD` permission.
    """

  @impl true
  def predicates,
    do: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]

  @impl true
  def command(msg, [filter, count_str, interval_str]) do
    filter = String.upcase(filter)

    response =
      with true <- filter in USWFilterConfig.existing_filters(),
           {count, _} <- Integer.parse(count_str),
           {interval, _} <- Integer.parse(interval_str),
           params <- %{
             guild_id: msg.guild_id,
             filter: filter,
             count: count,
             interval: interval
           },
           changeset <- USWFilterConfig.changeset(%USWFilterConfig{}, params),
           {:ok, _struct} <-
             Repo.insert(
               changeset,
               conflict_target: [:guild_id, :filter],
               on_conflict: [set: [count: count, interval: interval]]
             ) do
        "👌 updated configuration, will now allow max **#{count}**" <>
          " messages per **#{interval}**s in filter `#{filter}`"
      else
        false ->
          "🚫 `#{Helpers.clean_content(filter)}` is not a known filter"

        :error ->
          "🚫 either `count` or `interval` are not integers"

        error ->
          ErrorFormatters.fmt(msg, error)
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "🚫 expected 3 arguments (filter, count, interval), got some other amount"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
