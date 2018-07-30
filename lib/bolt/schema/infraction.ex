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
    |> validate_inclusion(:type, known_types())
    |> validate_expiry()
  end

  @spec validate_expiry(Changeset.t()) :: Changeset.t()
  defp validate_expiry(changeset) do
    type = get_field(changeset, :type)
    expiry = get_field(changeset, :expires_at)

    if type in ["tempmute", "temprole", "tempban"] and expiry == nil do
      add_error(changeset, :expires_at, "may not be `nil` for temporary infractions")
    else
      changeset
    end
  end

  def known_types do
    [
      "note",
      "tempmute",
      "mute",
      "unmute",
      "forced_nick",
      "temprole",
      "warning",
      "kick",
      "softban",
      "tempban",
      "ban",
      "unban"
    ]
  end
end
