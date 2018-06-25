defmodule Bolt.Schema.ModLogConfig do
  @moduledoc "Mod log configuration, used by the mod log emitter."

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key {:guild_id, :id, autogenerate: false}
  schema "modlogconfig" do
    field :channel_id, :id
    field :event, :string
  end

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(config, params \\ %{}) do
    config
    |> cast(params, [:guild_id, :channel_id, :event])
    |> validate_inclusion(:event, valid_events())
  end

  @doc "Return all known events that are valid in the database."
  @spec valid_events :: [String.t]
  def valid_events do
    [
      # Bot events
      "AUTOMOD",  # automod events
      "BOT_UPDATE",  # bot was updated
      "CONFIG_UPDATE",  # guild configuration update
      "INFRACTION_CREATE",  # infraction was created
      "INFRACTION_UPDATE",  # infraction was updated
      "INFRACTION_EVENTS",  # infraction events emitted through e.g. `tempban`

      # Gateway events
      "CHANNEL_CREATE",  # channel created
      "CHANNEL_UPDATE",  # channel updated
      "CHANNEL_DELETE",  # channel deleted
      "MESSAGE_EDIT",  # message edited
      "MESSAGE_DELETE",  # message deleted
      "GUILD_MEMBER_ADD",  # member joined
      "GUILD_MEMBER_UPDATE",  # member updated themselves
      "GUILD_MEMBER_REMOVE",  # member left
      "GUILD_ROLE_CREATE",  # role created
      "GUILD_ROLE_UPDATE",  # role updated
      "GUILD_ROLE_DELETE",  # role deleted
      "USER_UPDATE"  # user updated themselves
    ]
  end
end
