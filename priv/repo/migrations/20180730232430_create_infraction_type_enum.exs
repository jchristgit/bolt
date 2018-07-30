defmodule Bolt.Repo.Migrations.CreateInfractionTypeEnum do
  use Ecto.Migration

  def up do
    execute("""
    CREATE TYPE infraction_type AS ENUM (
      'note',
      'tempmute',
      'mute',
      'unmute',
      'temprole',
      'warning',
      'kick',
      'softban',
      'tempban',
      'ban'
    );
    """)
  end

  def down do
    execute("DROP TYPE infraction_type;")
  end
end
