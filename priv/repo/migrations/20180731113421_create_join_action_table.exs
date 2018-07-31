defmodule Bolt.Repo.Migrations.CreateJoinActionTable do
  use Ecto.Migration

  def change do
    execute(
      "CREATE TYPE join_action_type AS ENUM ('send_guild', 'send_dm');",
      "DROP TYPE join_action_type;"
    )

    create table("join_action") do
      add(:guild_id, :bigint, null: false)
      add(:action, :join_action_type, null: false)
      add(:data, :jsonb, null: false)
    end
  end
end
