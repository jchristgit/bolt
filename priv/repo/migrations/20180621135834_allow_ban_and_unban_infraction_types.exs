defmodule Bolt.Repo.Migrations.AllowBanAndUnbanInfractionTypes do
  use Ecto.Migration

  def up do
    drop(
      constraint(
        "infractions",
        "type_must_be_valid_type"
      )
    )

    create(
      constraint(
        "infractions",
        "type_must_be_valid_type",
        check:
          "type IN ('note', 'tempmute', 'mute', 'unmute', 'temprole', 'warning', 'kick', 'softban', 'tempban', 'ban', 'unban')"
      )
    )
  end

  def down do
    drop(
      constraint(
        "infractions",
        "type_must_be_valid_type"
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
