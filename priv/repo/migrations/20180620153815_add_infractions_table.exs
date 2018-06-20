defmodule Bolt.Repo.Migrations.AddInfractionsTable do
  use Ecto.Migration

  def change do
    create table("infractions") do
      add(:type, :string, null: false)

      add(:guild_id, :bigint, null: false)
      add(:user_id, :bigint, null: false)
      add(:actor_id, :bigint, null: false)

      add(:reason, :string, default: nil)
      # `data` handled through custom SQL

      # `expires_at` handled through custom SQL
      timestamps(type: :utc_datetime)
    end

    execute(
      "ALTER TABLE infractions ADD COLUMN data JSONB NOT NULL DEFAULT '{}'::JSONB",
      "ALTER TABLE infractions DROP COLUMN data"
    )

    execute(
      "ALTER TABLE infractions ADD COLUMN expires_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NULL",
      "ALTER TABLE infractions DROP COLUMN expires_at"
    )

    create(index("infractions", :guild_id))

    create(
      constraint(
        "infractions",
        "expiry_must_be_in_the_future",
        check: "expires_at = NULL OR expires_at > (NOW() AT TIME ZONE 'UTC')"
      )
    )

    create(
      constraint(
        "infractions",
        "type_must_be_valid_type",
        check:
          "type IN ('note', 'tempmute', 'mute', 'unmute', 'temprole', 'warning', 'kick', 'softban', 'tempban')"
      )
    )
  end
end
