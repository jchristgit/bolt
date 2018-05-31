# Bolt
Bolt is a Discord Bot designed for moderation, but also ships a variety of other useful commands.

## Setup
Install dependencies: `pipenv install --dev`.

Run migrations: `pw_migrate migrate --database postgresql://user:password@host/dbname`.

Copy `config-example.json` to `config.json` and insert your credentials.

Add the `BOLT_DATABASE_URL` and `BOTLOG_CHANNEL_ID` environment variables.
The latter is optional.

Finally, to run bolt, use `python -m bolt`.
