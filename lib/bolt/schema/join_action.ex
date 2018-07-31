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
    |> unique_constraint(:"role id",
      name: :join_action_guild_id_data__role_id__index,
      message: "is already set to be added to users who join"
    )
    |> unique_constraint(:"sending a dm",
      name: :join_action_send_dm_unique_for_guild,
      message: "is already set up, update the existing entry instead of adding new ones"
    )
    |> unique_constraint(:"sending to the given channel",
      name: :join_action_send_guild_unique_for_guild_and_channel,
      message: "is already set up, update the existing entry instead"
    )
  end
end
