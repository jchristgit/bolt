defmodule Bolt.Schema.StarboardConfig do
  @moduledoc "Configuration for the starboard on a server."

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key {:guild_id, :id, []}
  schema "starboard_config" do
    field(:channel_id, :id)
    field(:min_stars, :integer)
  end

  @type t :: %__MODULE__{}

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(event, params \\ %{}) do
    event
    |> cast(params, [:guild_id, :channel_id, :min_stars])
    |> validate_required([:guild_id, :channel_id, :min_stars])
    |> check_constraint(:min_stars,
      name: "min_stars_must_be_positive",
      message: "must be > 0"
    )
  end
end
