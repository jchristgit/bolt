defmodule Bolt.Repo.Migrations.RemoveEventIdInfractionJsonbAttribute do
  use Ecto.Migration

  def down do
    require Logger

    Logger.warn("cannot re-add `event_id` JSONB attribute to infractions.data")
  end

  def up do
    execute("UPDATE infractions SET data = data - 'event_id';")
  end
end
