defmodule Bolt.Schema.Event do
  @moduledoc """
  A time-based event that is set somewhere
  in the future. For example:
  - a reminder
  - a temporary action that needs to be revoked at a later date
  """

  import Ecto.Changeset
  use Ecto.Schema

  schema "events" do
    field(:timestamp, :utc_datetime)
    field(:event, :string)
    field(:data, :map)
  end

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(event, params \\ %{}) do
    alias Bolt.Events.Deserializer

    event
    |> cast(params, [:timestamp, :event, :data])
    |> validate_required([:timestamp, :event, :data])
    |> validate_inclusion(:event, Deserializer.valid_events())
  end
end
