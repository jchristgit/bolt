defmodule Bolt.Cogs.ModLog.Set do
  @moduledoc false

  @behaviour Nosedrum.Command

  alias Bolt.Commander.Checks
  alias Bolt.{Converters, ErrorFormatters, Helpers, ModLog, Repo}
  alias Bolt.Schema.ModLogConfig
  alias Nostrum.Api
  alias Nostrum.Struct.User
  import Ecto.Query, only: [from: 2]

  @impl true
  def usage, do: ["modlog set <event:str> <channel:textchannel>"]

  @impl true
  def description,
    do: """
    Set the given `event` to be logged in `channel`.
    `all` can be given in place of `event` in order to delete any existing configuration(s) and log all events to `channel`.
    Requires the `MANAGE_GUILD` permission.
    """

  @impl true
  def predicates,
    do: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]

  @impl true
  def command(msg, ["all", channel]) do
    response =
      with {:ok, channel} <- Converters.to_channel(msg.guild_id, channel),
           query <- from(config in ModLogConfig, where: config.guild_id == ^msg.guild_id),
           {total_deleted, _maybe_deleted_rows} <- Repo.delete_all(query),
           new_configs <-
             ModLogConfig.valid_events()
             |> Enum.map(
               &%{
                 guild_id: msg.guild_id,
                 channel_id: channel.id,
                 event: &1
               }
             ),
           {_total_inserted, _maybe_inserted_rows} <- Repo.insert_all(ModLogConfig, new_configs) do
        ModLog.emit(
          msg.guild_id,
          "CONFIG_UPDATE",
          "#{User.full_name(msg.author)} (`#{msg.author.id}`) set the log channel" <>
            " for ALL events to <##{channel.id}>"
        )

        if total_deleted > 0 do
          "👌 deleted #{total_deleted} existing configs," <>
            " will now log all events to <##{channel.id}>"
        else
          "👌 will now log all events to <##{channel.id}>"
        end
      else
        {:error, reason} ->
          "🚫 invalid channel: #{Helpers.clean_content(reason)}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, [event, channel]) do
    event = String.upcase(event)

    response =
      with true <- event in ModLogConfig.valid_events(),
           nil <- Repo.get_by(ModLogConfig, guild_id: msg.guild_id, event: event),
           {:ok, channel} <- Converters.to_channel(msg.guild_id, channel),
           config_map <- %{
             guild_id: msg.guild_id,
             channel_id: channel.id,
             event: event
           },
           changeset <- ModLogConfig.changeset(%ModLogConfig{}, config_map),
           {:ok, _created_config} <- Repo.insert(changeset) do
        ModLog.emit(
          msg.guild_id,
          "CONFIG_UPDATE",
          "#{User.full_name(msg.author)} (`#{msg.author.id}`) set the log channel" <>
            " for event `#{event}` to <##{channel.id}>"
        )

        "👌 will now log `#{event}` events in <##{channel.id}>"
      else
        false ->
          "🚫 unknown event: `#{Helpers.clean_content(event)}`"

        %ModLogConfig{channel_id: channel_id} ->
          "🚫 this event is already being logged in <##{channel_id}>"

        error ->
          ErrorFormatters.fmt(msg, error)
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `modlog set <event:str> <channel:textchannel>`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
