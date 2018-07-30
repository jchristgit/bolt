defmodule Bolt.Repo.Migrations.ChangeInfractionTypeColumnToEnum do
  use Ecto.Migration

  def up do
    execute("""
    ALTER TABLE infractions
      ALTER COLUMN type
        TYPE infraction_type
        USING type::infraction_type;
    """)
  end

  def down do
    execute("""
    ALTER TABLE infractions
      ALTER COLUMN type
        TYPE VARCHAR(255)
    """)
  end
end
