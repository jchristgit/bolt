defmodule Bolt.Repo.Migrations.DropEventsTable do
  use Ecto.Migration

  def up do
    drop(table("events"))
  end

  def down do
    create table("events", comment: "Time-based events") do
      add(:timestamp, :utc_datetime, comment: "Timestamp at which the event should be executed")
      add(:event, :string, comment: "Event type, chosen from enum")
      add(:data, :map, comment: "Additional metadata for the event")
    end
  end
end
