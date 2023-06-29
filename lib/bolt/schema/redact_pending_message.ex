defmodule Bolt.Schema.RedactPendingMessage do
  @moduledoc "A message pending later removal"

  alias Bolt.Schema.RedactConfig
  import Ecto.Changeset
  use Ecto.Schema

  @primary_key false
  schema "redact_pending_message" do
    field(:message_id, :id, primary_key: true)
    field(:channel_id, :id)
    belongs_to :config, RedactConfig
  end

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(message, params \\ %{}) do
    message
    |> cast(params, [:message_id, :channel_id, :config_id])
    |> foreign_key_constraint(:config_id)
  end
end
