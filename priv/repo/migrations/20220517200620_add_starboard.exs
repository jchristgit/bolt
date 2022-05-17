defmodule Bolt.Repo.Migrations.AddStarboard do
  use Ecto.Migration

  def change do
    create table(:starboard_config, primary_key: false, comment: "Starboard configuration for a server") do
      add :guild_id, :bigint, null: false, primary_key: true, comment: "Guild this configuration applies to"
      add :channel_id, :bigint, null: false, comment: "Channel to send starboard notifications in"
      add :min_stars, :smallint, null: false, comment: "Minimum stars for adding a message to the starboard"
    end

    create constraint(:starboard_config, :min_stars_must_be_positive, check: "min_stars > 0", comment: "Validates that at least one star is required for sending a message to the starboard")

    create table(:starboard_message, primary_key: false, comment: "Message that was added to the starboard") do
      add :guild_id, :bigint, null: false, comment: "Guild the message was sent in"
      add :channel_id, :bigint, null: false, comment: "Channel the original message was sent in"
      add :message_id, :bigint, null: false, primary_key: true, comment: "ID of the original message that was starred"
      add :starboard_message_id, :bigint, null: false, comment: "ID of the message showcasing the starred message"
    end
  end
end
