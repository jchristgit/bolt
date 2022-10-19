defmodule Bolt.Repo.Migrations.AddTimeoutForUswPunishmentsAndInfractionTypes do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    # Please don't question the alternative capitalizations here.
    execute("ALTER TYPE infraction_type ADD VALUE 'timeout';")
    execute("ALTER TYPE punishment_type ADD VALUE 'TIMEOUT';")
  end
end
