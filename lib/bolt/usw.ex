defmodule Bolt.USW do
  @moduledoc "USW - Uncomplicated Spam Wall"

  alias Bolt.Repo
  alias Bolt.Schema.USWFilterConfig
  alias Bolt.USW.Filters.{Burst}
  import Ecto.Query, only: [from: 2]

  @spec filter_to_fn(USWFilterConfig) ::
          (Nostrum.Struct.Message.t(), non_neg_integer(), non_neg_integer() ->
             :action | :passthrough)
  defp filter_to_fn(%USWFilterConfig{filter: "BURST"}), do: &Burst.apply/3

  @spec apply(Nostrum.Struct.Message.t()) :: :ok
  def apply(msg) do
    query =
      from(
        config in USWFilterConfig,
        where: [guild_id: ^msg.guild_id],
        select: config
      )

    case Repo.all(query) do
      nil ->
        :ok

      configurations ->
        configurations
        |> Stream.map(fn config ->
          fn ->
            func = filter_to_fn(config)
            func.(msg, config.count, config.interval)
          end
        end)
        |> Enum.find(&(&1 == :action))

        :ok
    end
  end
end
