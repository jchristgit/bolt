defmodule Bolt.Schema.AcceptAction do
  @moduledoc "An action to be ran when a member uses the `.accept` command."

  import Ecto.Changeset
  use Ecto.Schema

  schema "accept_action" do
    field(:guild_id, :id)
    field(:action, :string)
    field(:data, :map)
  end

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(action, params \\ %{}) do
    action
    |> cast(params, [:guild_id, :action, :data])
    |> validate_required([:guild_id, :action, :data])
    |> unique_constraint(:"delete invocation",
      name: :accept_action_guild_id_action_index,
      message: "is already set to run on accept"
    )
    |> unique_constraint(:"role id",
      name: :accept_action_guild_id_data__role_id__index,
      message: "is already set to be added or removed on accept"
    )
  end
end
