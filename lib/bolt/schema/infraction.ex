defmodule Bolt.Schema.Infraction do
  @moduledoc "An infraction applying to a given user."

  import Ecto.Changeset
  use Ecto.Schema

  schema "infractions" do
    field(:type, :string)

    field(:guild_id, :id)
    field(:user_id, :id)
    field(:actor_id, :id)

    field(:reason, :string, default: nil)
    field(:data, :map, default: %{})

    field(:expires_at, :utc_datetime, default: nil)
    field(:active, :boolean, default: true)
    timestamps(type: :utc_datetime)
  end

  @type t :: %__MODULE__{}

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(event, params \\ %{}) do
    event
    |> cast(params, [
      :type,
      :guild_id,
      :user_id,
      :actor_id,
      :reason,
      :data,
      :expires_at,
      :active
    ])
    |> validate_required([:type, :guild_id, :user_id, :actor_id])
    |> check_constraint(:expires_at,
      name: "expiry_required_on_timed_infractions",
      message: "must be set for timed infractions"
    )
  end

  # This must be differentiated because bolt may be late in processing the event queue.
  def active?(%__MODULE__{type: "timeout", expires_at: expiry}),
    do: DateTime.compare(expiry, DateTime.utc_now()) != :lt

  def active?(%__MODULE__{active: active, expires_at: expiry}) when expiry != nil, do: active
  def active?(%__MODULE__{}), do: false
end
