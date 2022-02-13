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
    with {:cache, {:ok, %Guild{vanity_url_code: code}}} when not is_nil(code) <-
           {:cache, GuildCache.get(guild_id)},
         {:api, {:ok}} <-
           {:api, Api.request(:delete, "/guilds/#{guild_id}/vanity-url")} do
      ModLog.emit(guild_id, "AUTOMOD", "deleted vanity URL `#{code}` as part of action")
    else
      {:cache, {:ok, %Guild{vanity_url_code: nil}}} ->
        # We don't have a vanity URL, our job is done
        :ok

      {:api, {:error, reason}} ->
        IO.inspect(reason, label: "why")
        ModLog.emit(guild_id, "ERROR", "failed to delete vanity URLs due to Discord API error")
    end
  end

  defimpl String.Chars do
    def to_string(_options) do
      "delete the vanity URL"
    end
  end
end
