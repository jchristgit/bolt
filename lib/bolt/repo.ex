defmodule Bolt.Repo do
  use Ecto.Repo,
    otp_app: :bolt,
    adapter: Ecto.Adapters.Postgres
end
