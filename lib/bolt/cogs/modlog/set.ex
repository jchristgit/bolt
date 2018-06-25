defmodule Bolt.Cogs.ModLog.Set do
  @moduledoc false

  alias Bolt.Converters
  alias Bolt.Helpers
  alias Bolt.ModLog
  alias Bolt.Repo
  alias Bolt.Schema.ModLogConfig
  alias Nostrum.Api
  alias Nostrum.Struct.User
  import Ecto.Query, only: [from: 2]

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
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

        {:error, %Ecto.Changeset{} = changeset} ->
          errors = Helpers.format_changeset_errors(changeset)
          "🚫 invalid options:\n#{errors}"

        {:error, reason} ->
          "🚫 error: #{reason}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "🚫 subcommand expects two arguments: event to log (or `all`) and channel to log in"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
