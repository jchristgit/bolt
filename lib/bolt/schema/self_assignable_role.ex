defmodule Bolt.Schema.SelfAssignableRoles do
  @moduledoc "Roles that are self-assignable by users."

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key {:guild_id, :id, []}
  schema "selfassignableroles" do
    field :roles, {:array, :id}
  end

  def changeset(selfassignableroles, params \\ %{}) do
    selfassignableroles
    |> cast(params, [:guild_id, :roles])
    |> validate_inclusion(:guild_id, 0..0xFFFFFFFFFFFFFFFF)
    |> unique_constraint(:guild_id)
  end
end
