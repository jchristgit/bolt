defmodule Bolt.Schema.Action do
  @moduledoc "A single action to run as part of a group"

  alias Bolt.Action
  alias Bolt.Schema.ActionGroup
  import Ecto.Changeset
  import PolymorphicEmbed, only: [cast_polymorphic_embed: 3]
  use Ecto.Schema

  schema "action" do
    field :module, PolymorphicEmbed,
      types: [
        clear_gatekeeper_actions: Action.ClearGatekeeperActions,
        delete_invites: Action.DeleteInvites,
        delete_vanity_url: Action.DeleteVanityUrl
      ],
      on_type_not_found: :raise,
      on_replace: :update

    belongs_to :group, ActionGroup
  end

  @type t :: %__MODULE__{}

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(action, params \\ %{}) do
    action
    |> cast(params, [])
    |> cast_assoc(:group)
    |> cast_polymorphic_embed(:module, required: true)
  end
end
