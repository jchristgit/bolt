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
    with {:ok, guild} <- GuildCache.get(guild_id),
         %Nostrum.Struct.Guild{} <- guild,
         %Guild{} <- guild,
         %Guild{vanity_url_code: code} <- guild,
         %Guild{vanity_url_code: code} when not is_nil(code) <- guild,
         {:ok, %Guild{vanity_url_code: nil}} <-
           Api.modify_guild(guild_id, [vanity_url_code: nil], reason) do
      ModLog.emit(guild_id, "AUTOMOD", "deleted vanity URL `#{code}` as part of action")
    else
      {:ok, %Guild{vanity_url_code: nil}} ->
        # We don't have a vanity URL, our job is done
        :ok

      {:error, _reason} ->
        ModLog.emit(guild_id, "ERROR", "failed to delete vanity URLs due to Discord API error")
    end
  end

  defimpl String.Chars do
    def to_string(_options) do
      "delete the vanity URL"
    end
  end
end
