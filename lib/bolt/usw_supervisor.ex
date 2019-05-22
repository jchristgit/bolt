defmodule Bolt.USWSupervisor do
  @moduledoc """
  Supervises processes of the Uncomplicated Spam Wall.
  """

  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      # A lock that ensures that USW does not react
      # twice when a user hits configured limits.
      {Bolt.USW.Deduplicator, name: Bolt.USW.Deduplicator},

      # Escalates the punishment time of users which were punished recently.
      {Bolt.USW.Escalator, name: Bolt.USW.Escalator}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
