defmodule Bolt.Schema.JoinAction do
  @moduledoc "An action to be ran when a member joins the server."

  import Ecto.Changeset
  use Ecto.Schema

  schema "join_action" do
    field(:guild_id, :id)
    field(:action, :string)
    field(:data, :map)
  end

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(action, params \\ %{}) do
    action
    |> cast(params, [:guild_id, :action, :data])
    |> validate_required([:guild_id, :action, :data])
  end
end
