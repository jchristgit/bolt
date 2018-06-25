defmodule Bolt.Cogs.ModLog.Status do
  @moduledoc false

  alias Bolt.Repo
  alias Bolt.Schema.ModLogConfig
  import Ecto.Query, only: [from: 2]
  alias Nostrum.Api

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, []) do
    query = from(config in ModLogConfig, where: config.guild_id == ^msg.guild_id, select: config)

    response =
      case Repo.all(query) do
        [] ->
          "❌ modlog is not configured"

        config_rows ->
          event_log_descriptions =
            config_rows
            |> Enum.group_by(
              fn row -> row.event end,
              fn row -> row.channel_id end
            )
            |> Map.to_list()
            |> Stream.map(fn {event, channels} ->
              {event, Stream.map(channels, &"<##{&1}>")}
            end)
            |> Enum.map(fn {event, channels} ->
              "• `#{event}` is logged in #{Enum.join(channels, ", ")}"
            end)

          "**Mod log configuration**\n#{event_log_descriptions}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "🚫 this subcommand takes no arguments"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
