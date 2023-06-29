defmodule Bolt.Repo.Migrations.AddRedactTables do
  use Ecto.Migration

  def change do
    create table(:redact_config, comment: "Auto-redact configuration per user and guild") do
      add :guild_id, :bigint, null: false, comment: "Guild this configuration applies on"
      add :author_id, :bigint, null: false, comment: "User whose settings this represents"
      add :age_in_seconds, :integer, null: false, comment: "Minimum age of messages, in seconds, before considering for deletion"
      add :excluded_channels, {:array, :bigint}, null: false, comment: "Channels to exclude from deletion on this guild"
      add :enabled, :boolean, null: false, comment: "Whether redaction should be run"
    end

    create unique_index(:redact_config, [:guild_id, :author_id], comment: "Each guild and author should only have one configuration entry")
    create constraint(:redact_config, :age_in_seconds, check: "age_in_seconds > (60 * 60)", comment: "Messages should be at least an hour old before considering for deletion")

    create table(:redact_channel_ingestion_state, primary_key: false, comment: "Auto-redact ingestion state per channel") do
      add :channel_id, :bigint, null: false, primary_key: true, comment: "Channel this entry applies to"
      add :last_processed_message_id, :bigint, null: false, comment: "Last message ID in the channel that was processed, only ever increments"
      add :enabled, :boolean, null: false, comment: "Whether ingestion on this channel is enabled or was paused due to an error", default: true
    end

    # PostgreSQL is a message queue(tm)
    create table(:redact_pending_message, primary_key: false, comment: "Messages to be redacted later, by user and channel") do
      add :message_id, :bigint, null: false, primary_key: true, comment: "Message ID that should be deleted later"
      add :channel_id, :bigint, null: false, comment: "Channel this message belongs to"
      add :config_id, references(:redact_config, on_delete: :delete_all), null: false, comment: "Configuration relevant for this entry"
    end
  end
end
