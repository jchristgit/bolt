# Bolt
A high-quality Discord moderation bot, intended for large guilds.


## Running locally
**Initial setup**:
- Set the environment variable `BOT_TOKEN` to your bot token
- Set the environment variable `PGSQL_URL` to your PostgreSQL database URL, e.g. `postgres://user:pass@host/dbname`
- `mix deps.get`
- `mix ecto.migrate --all`

**Running with iex**:
- `iex -S mix`


## Configuration
You can configure the prefix used by using the environment variable `BOT_PREFIX`.
If you want to, you can set up a bot log channel with the `BOTLOG_CHANNEL` environment
variable - set this to the channel ID that you want bot events logged in.

To configure the users able to use the `sudo` commands, set the `SUPERUSERS` environment
variable to a colon (`:`) separated list of user IDs that can use these commands.
