# Bolt

A Discord guild moderation bot for managing large servers.

## Running locally

**Initial setup**:
- Set the environment variable `BOT_TOKEN` to your bot token
- Set the environment variable `PGSQL_URL` to your PostgreSQL database URL,
  e.g. `postgres://user:pass@host/dbname`
- `mix deps.get`
- `mix ecto.migrate --all`

**Running with iex**:
- `iex -S mix`


## Deployment

I deploy via Ansible, see [`ansible/README.md`](ansible/README.md) for details.


## Configuration

You can configure the prefix used by using the environment variable
`BOT_PREFIX`.  If you want to, you can set up a bot log channel with the
`BOTLOG_CHANNEL` environment variable - set this to the channel ID that you
want bot events logged in.

To configure the users able to use the `sudo` commands, set the `SUPERUSERS`
environment variable to a colon (`:`) separated list of user IDs that can use
these commands.

## Monitoring

Bolt runs a munin node which listens on localhost, port 4949 by default. This
node can be used to inspect live BEAM runtime statistics along with information
about the Discord servers bolt is on.

To use it, point a munin master to the host that bolt runs on, or simply run
`nc localhost 4949` to give it a try.


<!-- vim: set textwidth=80 sw=2 ts=2: -->
