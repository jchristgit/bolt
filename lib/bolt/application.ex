defmodule Bolt.Application do
  @moduledoc """
  The entry point for bolt.
  Starts the required processes, including the gateway consumer.
  """

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

      # A lock that ensures that USW does not react
      # twice when a user hits configured limits.
      {Bolt.USW.Deduplicator, name: Bolt.USW.Deduplicator},

      # Escalates the punishment time of users which were punished recently.
      {Bolt.USW.Escalator, name: Bolt.USW.Escalator},

      # Caches messages for mod log purposes.
      {Bolt.MessageCache, name: Bolt.MessageCache},

      # Holds Aho-Corasick trees used for filtering messages.
      {Bolt.Filter, name: Bolt.Filter},

      # Consumes gateway events.
      Bolt.Consumer
    ]

    options = [strategy: :rest_for_one, name: Bolt.Supervisor]
    Supervisor.start_link(children, options)
  end
end
