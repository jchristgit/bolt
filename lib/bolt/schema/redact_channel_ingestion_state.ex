defmodule Bolt.Schema.RedactChannelIngestionState do
  @moduledoc "Per-channel redact ingestion worker state"

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key false
  schema "redact_channel_ingestion_state" do
    field(:channel_id, :id, primary_key: true)
    field(:last_processed_message_id, :id)
    field(:enabled, :boolean)
  end

  @type t :: %__MODULE__{}

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(state, params \\ %{}) do
    state
    |> cast(params, [:channel_id, :last_processed_message_id, :enabled])
    |> validate_required([:channel_id, :last_processed_message_id])
    |> unique_constraint(:redact_channel_ingestion_state_pkey)
  end
end
