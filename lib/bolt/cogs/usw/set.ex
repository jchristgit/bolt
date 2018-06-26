defmodule Bolt.Cogs.USW.Set do
  @moduledoc false

  alias Bolt.Helpers
  alias Bolt.Repo
  alias Bolt.Schema.USWFilterConfig
  alias Nostrum.Api

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
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

        {:error, %Ecto.Changeset{} = changeset} ->
          readable_errors =
            changeset
            |> Helpers.format_changeset_errors()
            |> Stream.map(&Helpers.clean_content(&1))
            |> Enum.join("\n")

          "🚫 encountered errors inserting settings:\n#{readable_errors}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "🚫 expected 3 arguments (filter, count, interval), got some other amount"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
