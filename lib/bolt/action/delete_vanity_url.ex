defmodule Bolt.Action.DeleteVanityUrl do
  @moduledoc "Delete a guild's vanity URL, if present."
  @behaviour Bolt.Action

  alias Bolt.ModLog
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Guild
  import Ecto.Changeset
  require Logger
  use Ecto.Schema

  embedded_schema do
  end

  def changeset(action, params) do
    action
    |> cast(params, [])
  end

  def run(_options, %{guild_id: guild_id, audit_log_reason: reason}) do
    cached_guild = GuildCache.get(guild_id)
    IO.inspect(cached_guild, label: "cached guild")

    with {:ok, %Guild{vanity_url_code: code}} when is_bitstring(code) <- cached_guild,
         {:ok, %Guild{vanity_url_code: nil}} <-
           Api.modify_guild(guild_id, [vanity_url_code: nil], reason) do
      ModLog.emit(guild_id, "AUTOMOD", "deleted vanity URL `#{code}` as part of action")
    else
      {:ok, %Guild{vanity_url_code: nil}} ->
        # We don't have a vanity URL, our job is done
        :ok

      {:error, _reason} ->
        ModLog.emit(guild_id, "ERROR", "failed to delete vanity URLs due to Discord API error")

      other ->
        Logger.error("got #{inspect(other)} instead of guild")
    end
  end

  defimpl String.Chars do
    def to_string(_options) do
      "delete the vanity URL"
    end
  end
end
