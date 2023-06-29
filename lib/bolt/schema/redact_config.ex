defmodule Bolt.Schema.RedactConfig do
  @moduledoc "Per-guild per-user redact configuration"

  alias Bolt.Schema.RedactPendingMessage
  import Ecto.Changeset
  use Ecto.Schema

  schema "redact_config" do
    field(:guild_id, :id)
    field(:author_id, :id)
    field(:age_in_seconds, :integer)
    field(:excluded_channels, {:array, :id})
    field(:enabled, :boolean)
    has_many :pending_messages, RedactPendingMessage, foreign_key: :config_id
  end

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(config, params \\ %{}) do
    config
    |> cast(params, [:guild_id, :author_id, :age_in_seconds, :excluded_channels, :enabled])
    |> validate_required([:guild_id, :author_id, :age_in_seconds, :excluded_channels, :enabled])
    |> check_constraint(:age_in_seconds,
      name: "age_within_bounds",
      message: "needs to be 1 hour or older"
    )
    |> unique_constraint([:guild_id, :author_id])
  end
end
