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
      Bolt.Repo,
      {Bolt.Events.Handler, name: Bolt.Events.Handler},
      {Bolt.Commander.Server, name: Bolt.Commander.Server},
      {Bolt.Paginator, name: Bolt.Paginator},
      {Bolt.ModLog.Silencer, name: Bolt.ModLog.Silencer},
      {Bolt.USW.Deduplicator, name: Bolt.USW.Deduplicator},
      {Bolt.USW.Escalator, name: Bolt.USW.Escalator},
      {Bolt.MessageCache, name: Bolt.MessageCache},
      {Bolt.Filter, name: Bolt.Filter},
      Bolt.Consumer
    ]

    options = [strategy: :rest_for_one, name: Bolt.Supervisor]
    Supervisor.start_link(children, options)
  end
end
