# Bolt
Bolt is a Discord Bot designed for moderation, but also ships a variety of other useful commands.

## Setup
Install dependencies: `pipenv install --dev`.

Run migrations: `pw_migrate migrate --database postgresql://user:password@host/dbname`.

Copy `config-example.json` to `config.json` and insert your credentials.

Finally, to run bolt, use `python -m bolt`.
