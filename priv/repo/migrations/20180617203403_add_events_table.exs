defmodule Bolt.Repo.Migrations.AddEventsTable do
  use Ecto.Migration

  def change do
    create table("events", comment: "Time-based events") do
      add(:timestamp, :utc_datetime, comment: "Timestamp at which the event should be executed")
      add(:event, :string, comment: "Event type, chosen from enum")
      add(:data, :map, comment: "Additional metadata for the event")
    end
  end
end
