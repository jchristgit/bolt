# Bolt
Bolt is a Discord Bot designed for moderation, but also ships a variety of other useful commands.

## Setup
Install dependencies: `pipenv install --dev`.

Copy the alembic configuration in `alembic-defaults.ini` to `alembic.ini` and customize it to your needs.

Run migrations: `alembic upgrade head`.

Copy `config-example.json` to `config.json` and insert your credentials.

Finally, to run bolt, use `python -m bolt`.
