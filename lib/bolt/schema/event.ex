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

  def changeset(event, params \\ %{}) do
    event
    |> cast(params, [:timestamp, :event, :data])
    |> validate_required([:timestamp, :event, :data])
  end
end
