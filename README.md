# Bolt
A high-quality Discord moderation bot, intended for large guilds.


## Running locally
**Initial setup**:
- Set the environment variable `BOT_TOKEN` to your bot token
- Set the environment variable `PGSQL_URL` to your PostgreSQL database URL, e.g. `postgres://user:pass@host/dbname`
- `mix deps.get`

**Running with iex**:
- `iex -S mix`


## Configuration
You can configure the `prefixes` in `config/config.exs` to have
the bot listen to other prefixes than the default ones.
