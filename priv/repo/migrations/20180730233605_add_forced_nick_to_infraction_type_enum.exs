defmodule Bolt.Repo.Migrations.AddForcedNickToInfractionTypeEnum do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    execute("ALTER TYPE infraction_type ADD VALUE 'forced_nick';")
  end
end
