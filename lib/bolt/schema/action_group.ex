defmodule Bolt.Schema.ActionGroup do
  @moduledoc "A collection of actions to run"

  alias Bolt.Schema.Action
  import Ecto.Changeset
  use Ecto.Schema

  schema "action_group" do
    field :guild_id, :id
    field :name, :string
    field :deduplicate, :boolean, default: true

    has_many :actions, Action, foreign_key: :group_id, on_replace: :delete
  end

  @type t :: %__MODULE__{}

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(group, params \\ %{}) do
    group
    |> cast(params, [:guild_id, :name, :deduplicate])
    |> cast_assoc(:actions)
    |> validate_length(:name, min: 1, max: 30)
    |> unique_constraint([:name, :guild_id])
  end
end
