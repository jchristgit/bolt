defmodule Bolt.Application do
  use Application

  def start(_type, _args) do
    children = [
      Bolt.Repo,
      {Bolt.Events.Handler, name: Bolt.Events.Handler},
      {Bolt.Commander.Server, name: Bolt.Commander.Server},
      {Bolt.Paginator, name: Bolt.Paginator},
      Bolt.Consumer
    ]

    options = [strategy: :rest_for_one, name: Bolt.Supervisor]
    Supervisor.start_link(children, options)
  end
end
