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
    timestamps(type: :utc_datetime)
  end

  def changeset(event, params \\ %{}) do
    event
    |> cast(params, [:type, :guild_id, :user_id, :actor_id, :reason, :data, :expires_at])
    |> validate_required([:type, :guild_id, :user_id, :actor_id])
    |> validate_inclusion(:type, [
      "note",
      "tempmute",
      "mute",
      "unmute",
      "temprole",
      "warning",
      "kick",
      "softban",
      "tempban",
      "ban",
      "unban"
    ])
    |> validate_expiry()
  end

  defp validate_expiry(changeset) do
    type = get_field(changeset, :type)
    expiry = get_field(changeset, :expires_at)

    if type in ["tempmute", "temprole", "tempban"] and expiry == nil do
      add_error(changeset, :expires_at, "may not be `nil` for temporary infractions")
    else
      changeset
    end
  end
end
