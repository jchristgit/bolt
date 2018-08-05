ExUnit.start()

# Start the Ecto repository so we can use it in tests.
{:ok, _pid} = Supervisor.start_link([{Bolt.Repo, name: Bolt.Repo}], strategy: :one_for_one)
Ecto.Adapters.SQL.Sandbox.mode(Bolt.Repo, :manual)
