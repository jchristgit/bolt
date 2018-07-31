defmodule Bolt.Repo.Migrations.AddUniqueConstraintsToAcceptActions do
  use Ecto.Migration

  def change do
    # Deleting a message invocation multiple times does not make sense
    create(
      unique_index(
        "accept_action",
        [:guild_id, :action],
        where: "action = 'delete_invocation'"
      )
    )

    # Adding or removing the same role ID multiple times does not make sense
    create(
      unique_index(
        "accept_action",
        [:guild_id, "(data->'role_id')"],
        where: "data ? 'role_id'"
      )
    )
  end
end
