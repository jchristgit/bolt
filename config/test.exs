import Config

config :logger,
  level: :warn

config :bolt, Bolt.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("PGSQL_TEST_URL") || "postgres://bolt:@localhost/bolt_test",
  pool: Ecto.Adapters.SQL.Sandbox
