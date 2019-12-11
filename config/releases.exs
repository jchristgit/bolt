import Config

config :bolt,
  botlog_channel: System.get_env("BOTLOG_CHANNEL"),
  ecto_repos: [Bolt.Repo],
  prefix: System.get_env("BOT_PREFIX") || ".",
  superusers:
    (System.get_env("SUPERUSERS") || "")
    |> String.split(":", trim: true)
    |> Enum.map(fn user_id ->
      {value, _} = Integer.parse(user_id)
      value
    end),
  web_domain: System.get_env("WEB_DOMAIN")

config :nosedrum,
  prefix: System.get_env("BOT_PREFIX") || "."

config :bolt, Bolt.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("PGSQL_URL")

config :nostrum,
  token: System.get_env("BOT_TOKEN"),
  num_shards: :auto

config :crow,
  ip: {127, 0, 0, 1},
  plugins: [
    Bolt.CrowPlugins.GuildMembers,
    Bolt.CrowPlugins.GuildMessageCounts,
    CrowPlugins.BEAM.ContextSwitches,
    CrowPlugins.BEAM.GarbageCollections,
    CrowPlugins.BEAM.IO,
    CrowPlugins.BEAM.Memory,
    CrowPlugins.BEAM.SystemInfo
  ]

config :tzdata, :autoupdate, :disabled

config :logger,
  level: :info
