defmodule Bolt.Cogs.ModLog.Unset do
  @moduledoc false

  alias Bolt.Helpers
  alias Bolt.ModLog
  alias Bolt.Repo
  alias Bolt.Schema.ModLogConfig
  alias Nostrum.Api
  alias Nostrum.Struct.User

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, ["all"]) do
    import Ecto.Query, only: [from: 2]

    # log before the log channel is deleted to ensure this log still appears there
    ModLog.emit(
      msg.guild_id,
      "CONFIG_UPDATE",
      "#{User.full_name(msg.author)} (`#{msg.author.id}`) unset the log channel" <>
        " for ALL events"
    )

    query = from(config in ModLogConfig, where: config.guild_id == ^msg.guild_id)
    {deleted, nil} = Repo.delete_all(query)

    response = "👌 deleted #{deleted} existing mod log configuration(s)"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, [event]) do
    event = String.upcase(event)

    response =
      if event not in ModLogConfig.valid_events() do
        "🚫 `#{Helpers.clean_content(event)}` is not a known event"
      else
        case Repo.get_by(ModLogConfig, guild_id: msg.guild_id, event: event) do
          nil ->
            "🚫 event `#{event}` has no log channel configured"

          config ->
            {:ok, _struct} = Repo.delete(config)

            ModLog.emit(
              msg.guild_id,
              "CONFIG_UPDATE",
              "#{User.full_name(msg.author)} (`#{msg.author.id}`) unset the log channel" <>
                " for event `#{event}` (was <##{config.channel_id}>)"
            )

            "👌 unset the log channel for `#{event}` (was <##{config.channel_id}>)"
        end
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "🚫 subcommand expects one arguments: event to unset, or `all`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
