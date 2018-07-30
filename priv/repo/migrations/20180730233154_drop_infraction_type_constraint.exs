defmodule Bolt.Repo.Migrations.DropInfractionTypeConstraint do
  use Ecto.Migration

  def up do
    drop(constraint("infractions", "type_must_be_valid_type"))
  end
end
