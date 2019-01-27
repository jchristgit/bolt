use Mix.Config

config :bolt,
  base_doc_url: System.get_env("BASE_DOC_URL"),
  botlog_channel: System.get_env("BOTLOG_CHANNEL"),
  ecto_repos: [Bolt.Repo],
  prefix: System.get_env("BOT_PREFIX") || ".",
  superusers:
    (System.get_env("SUPERUSERS") || "")
    |> String.split(":", trim: true)
    |> Enum.map(fn user_id ->
      {value, _} = Integer.parse(user_id)
      value
    end)

config :bolt, Bolt.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("PGSQL_URL")

config :nostrum,
  token: System.get_env("BOT_TOKEN"),
  num_shards: :auto

config :logger,
  level: :warn
