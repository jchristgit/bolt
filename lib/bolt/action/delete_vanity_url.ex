defmodule Bolt.Action.DeleteVanityUrl do
  @behaviour Bolt.Action

  # alias Bolt.ModLog
  # alias Nostrum.Api
  # alias Nostrum.Cache.GuildCache
  # alias Nostrum.Struct.Guild
  import Ecto.Changeset
  use Ecto.Schema

  embedded_schema do
  end

  def changeset(action, params) do
    action
    |> cast(params, [])
  end

  def run(_options, %{guild_id: _guild_id}) do
    # Needs upstream support
    # with {:ok, %Guild} <- GuildCache.get(guild_id)} do
    #   {:ok, guild}
    # end
  end

  defimpl String.Chars do
    def to_string(_options) do
      "delete the vanity URL"
    end
  end
end
