defmodule Bolt.Application do
  @moduledoc """
  The entry point for bolt.

  Starts the required processes, including the gateway consumer supervisor.
  """

  alias Bolt.CrowPlugins.GuildMessageCounts
  use Application

  @impl true
  @spec start(
          Application.start_type(),
          term()
        ) :: {:ok, pid()} | {:ok, pid(), Application.state()} | {:error, term()}
  def start(_type, _args) do
    children = [
      # Manages the PostgreSQL connection.
      Bolt.Repo,

      # Handles timed events of infractions.
      {Bolt.Events.Handler, name: Bolt.Events.Handler},
      Nosedrum.Storage.ETS,

      # Allows for embed pagination.
      {Bolt.Paginator, name: Bolt.Paginator},

      # Stores guilds with silenced mod logs.
      {Bolt.ModLog.Silencer, name: Bolt.ModLog.Silencer},

      # Caches messages for mod log purposes.
      {Bolt.MessageCache, name: Bolt.MessageCache},

      # Holds Aho-Corasick trees used for filtering messages.
      {Bolt.Filter, name: Bolt.Filter},

      # Supervises the Uncomplicated Spam Wall processes.
      Bolt.USWSupervisor,

      # Supervises Discord Gateway event consumers.
      Bolt.ConsumerSupervisor
    ]

    bootstrap_ets_tables()
    options = [strategy: :rest_for_one, name: Bolt.Supervisor]
    Supervisor.start_link(children, options)
  end

  def bootstrap_ets_tables do
    :ets.new(GuildMessageCounts.table_name(), [
      {:write_concurrency, true},
      :ordered_set,
      :public,
      :named_table
    ])
  end
end
