# Ansible deployment files

If you feel like deploying bolt, you can use the provided ansible roles, mainly
the `bolt` role.  Deployment is done through an Erlang release. At the very
least, the `bolt_bot_token` variable is required. The rest of the variables is
documented in the [role defaults](./roles/bolt/defaults/main.yml).

Migrations are handled automatically.

<!-- vim: set textwidth=80 sw=2 ts=2: -->
