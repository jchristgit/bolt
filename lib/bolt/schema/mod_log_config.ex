defmodule Bolt.Schema.ModLogConfig do
  @moduledoc "Mod log configuration, used by the mod log emitter."

  import Ecto.Changeset
  use Ecto.Schema

  @primary_key false
  schema "modlogconfig" do
    field(:guild_id, :id, primary_key: true)
    field(:event, :string, primary_key: true)
    field(:channel_id, :id)
  end

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(config, params \\ %{}) do
    config
    |> cast(params, [:guild_id, :channel_id, :event])
    |> validate_inclusion(:event, valid_events())
  end

  @doc "Return all known events that are valid in the database."
  @spec valid_events :: [String.t()]
  def valid_events do
    [
      ## BOT EVENTS
      # automod events
      "AUTOMOD",
      # bot was updated
      "BOT_UPDATE",
      # guild configuration update
      "CONFIG_UPDATE",
      # guild-specific error occurred
      "ERROR",
      # infraction was created
      "INFRACTION_CREATE",
      # infraction was updated
      "INFRACTION_UPDATE",
      # infraction events emitted through e.g. `tempban`
      "INFRACTION_EVENTS",

      ## COMMAND EVENTS
      "MESSAGE_CLEAN",

      ## GATEWAY EVENTS
      # channel created
      "CHANNEL_CREATE",
      # channel updated
      "CHANNEL_UPDATE",
      # channel deleted
      "CHANNEL_DELETE",
      # message edited
      "MESSAGE_EDIT",
      # message deleted
      "MESSAGE_DELETE",
      # member banned
      "GUILD_BAN_ADD",
      # member unbanned
      "GUILD_BAN_REMOVE",
      # member joined
      "GUILD_MEMBER_ADD",
      # member updated themselves
      "GUILD_MEMBER_UPDATE",
      # member left
      "GUILD_MEMBER_REMOVE",
      # role created
      "GUILD_ROLE_CREATE",
      # role updated
      "GUILD_ROLE_UPDATE",
      # role deleted
      "GUILD_ROLE_DELETE",
      # user updated themselves
      "USER_UPDATE"
    ]
  end
end
