defmodule Bolt.Schema.MuteRole do
  @moduledoc "The role to be applied when a member is muted."

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key {:guild_id, :id, []}
  schema "mute_role" do
    field(:role_id, :id)
  end

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(role, params \\ %{}) do
    role
    |> cast(params, [:guild_id, :role_id])
    |> validate_required([:guild_id, :role_id])
  end
end
