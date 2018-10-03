# Ansible deployment files
If you feel like deploying bolt, you can use the provided ansible roles, mainly the `bolt` role.
Deployment is done through Docker Swarm, the deployment role assumes that your target machine
is already part of a cluster. Deployment via [distillery](https://github.com/bitwalker/distillery)
may become a thing in the future to support hot upgrades along with other BEAM niceties.
The following variables are configurable, with the bold variables being required:

- **`bolt_postgres_password`**: Password to use for authenticating with PostgreSQL.
- **`bolt_bot_token`**: The Discord bot token to use
- `bolt_base_doc_url`: Base URL used for building documentation links in the built-in help.
- `bolt_botlog_channel`: The channel ID to be used for logging bot events.
- `bolt_superusers`: A colon-separated list of user IDs that may use the `sudo` command.

If you don't already have the required roles, you can install them using `ansible-galaxy`.
