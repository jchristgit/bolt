defmodule Bolt.Application do
  use Application

  def start(_type, _args) do
    children = [
      Bolt.Consumer
    ]

    options = [strategy: :one_for_one, name: Bolt.Supervisor]
    Supervisor.start_link(children, options)
  end
end
