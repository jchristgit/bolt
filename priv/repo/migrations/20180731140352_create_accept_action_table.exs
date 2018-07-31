defmodule Bolt.Repo.Migrations.CreateAcceptActionTable do
  use Ecto.Migration

  def change do
    execute(
      "CREATE TYPE accept_action_type AS ENUM ('add_role', 'remove_role');",
      "DROP TYPE accept_action_type;"
    )

    create table("accept_action") do
      add(:guild_id, :bigint, null: false)
      add(:action, :accept_action_type, null: false)
      add(:data, :jsonb, null: false)
    end
  end
end
