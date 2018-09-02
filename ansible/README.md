# Ansible deployment files
If you feel like deploying bolt, you can use the provided ansible roles, mainly the `bolt` role.
Bolt itself will run in a Docker container on the host network and use the host's PostgreSQL
database by default. Deployment via [distillery](https://github.com/bitwalker/distillery)
may become a thing in the future to support hot upgrades along with other BEAM niceties.
The following variables are configurable, with the bold variables being required:

- `bolt.postgres.host`: PostgreSQL database host.

  Note that the role currently only supports installing PostgreSQL on the host,
  and will create the database along with the configured user there.
  Defaults to `localhost`.

- `bolt.postgres.database`: PostgreSQL database name.
  Defaults to `bolt`.

- `bolt.postgres.user`: User to use for authenticating with PostgreSQL.
  Defaults to `bolt`.

- **`bolt.postgres.password`**: Password to use for authenticating with PostgreSQL.
- **`bolt.bot_token`**: The Discord bot token to use
- `bolt.base_doc_url`: Base URL used for building documentation links in the built-in help.
- `bolt.botlog_channel`: The channel ID to be used for logging bot events.
- `bolt.superusers`: A colon-separated list of user IDs that may use the `sudo` command.

You may need to specify
```ini
hash_behaviour = merge
```
in your `ansible.cfg` in order to be able to override single variables.
