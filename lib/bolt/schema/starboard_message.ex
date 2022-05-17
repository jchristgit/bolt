defmodule Bolt.Schema.StarboardMessage do
  @moduledoc "A message that ended up on the starboard."

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key {:message_id, :id, []}
  schema "starboard_message" do
    field(:guild_id, :id)
    field(:channel_id, :id)
    field(:starboard_message_id, :id)
  end

  @type t :: %__MODULE__{}

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(event, params \\ %{}) do
    event
    |> cast(params, [:guild_id, :channel_id, :message_id, :starboard_message_id])
    |> validate_required([:guild_id, :channel_id, :message_id, :starboard_message_id])
  end
end
