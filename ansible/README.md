# Ansible deployment files

If you feel like deploying bolt, you can use the provided ansible roles, mainly
the `bolt` role.  Deployment is done through a Docker container.  The following
variables are configurable, with the bold variables being required:

- **`bolt_postgres_password`**: Password to use for authenticating with
  PostgreSQL.

- **`bolt_bot_token`**: The Discord bot token to use

- `bolt_web_domain`: The domain at which Bolt's documentation is hosted. Bolt
  expects a Munin master to run at `munin.{{ bolt_web_domain }}` and links to it
  throughout various commands.

- `bolt_botlog_channel`: The channel ID to be used for logging bot events.

- `bolt_superusers`: A colon-separated list of user IDs that may use the `sudo`
  command.

If you don't already have the required roles, you can install them using `ansible-galaxy`.

Migrations are not handled automatically. The simplest way to run these is to
`remote_console` into a live instance and call Ecto.

<!-- vim: set textwidth=80 sw=2 ts=2: -->
