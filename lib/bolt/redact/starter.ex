defmodule Bolt.Redact.Starter do
  @moduledoc "Starts up the redact subsystem worker processes"

  alias Bolt.Repo
  alias Bolt.Redact
  alias Bolt.Schema.RedactConfig
  import Ecto.Query, only: [from: 2]
  require Logger
  use GenServer, restart: :transient

  def start_link(options) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  def init(args) do
    {:ok, nil, {:continue, args}}
  end

  def handle_continue(:ok, state) do
    :ok = Nostrum.ConsumerGroup.join()

    receive do
      {:event, {:READY, _, _}} -> :ok
    after
      10_000 -> :ok
    end

    :ok = :pg.leave(Nostrum.ConsumerGroup, :consumers, self())
    # Make sure cache is actually full.... jesus christ, this is hacky
    :timer.sleep(5_000)

    guild_ids_query =
      from config in RedactConfig,
        distinct: true,
        select: config.guild_id

    started =
      guild_ids_query
      |> Repo.all()
      |> Stream.map(&fetch_and_start_guild_workers/1)
      |> Enum.sum()

    Logger.debug("Started #{started} redact workers")

    {:stop, :normal, state}
  end

  defp fetch_and_start_guild_workers(guild_id) do
    configs_query =
      from config in RedactConfig,
        where: config.guild_id == ^guild_id

    channel_ids = Redact.relevant_channels(guild_id, [])

    configs_query
    |> Repo.all()
    |> Redact.configure_guild_workers(channel_ids)
    |> Enum.count()
  end
end
