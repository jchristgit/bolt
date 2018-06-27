defmodule Bolt.Repo.Migrations.CreateUswPunishmentConfigTable do
  use Ecto.Migration

  def change do
    execute(
      "CREATE TYPE punishment_type AS ENUM ('TEMPROLE');",
      "DROP TYPE punishment_type;"
    )

    create table(
             "usw_punishment_config",
             primary_key: false,
             comment: "Configuration for the USW anti-spam module"
           ) do
      add(
        :guild_id,
        :bigint,
        primary_key: true,
        comment: "The guild ID this configuration row applies to"
      )

      add(:duration, :integer, comment: "The duration (in seconds) that the punishment will last")

      add(
        :punishment,
        :punishment_type,
        nullable: false,
        comment: "The configured punishment type for automod actions"
      )

      add(
        :data,
        :map,
        nullable: false,
        default: %{},
        comment: "Additional metadata used with the given punishment type"
      )
    end
  end
end
