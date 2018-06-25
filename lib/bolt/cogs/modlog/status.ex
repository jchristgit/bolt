defmodule Bolt.Cogs.ModLog.Status do
  @moduledoc false

  alias Bolt.Constants
  alias Bolt.Repo
  alias Bolt.Schema.ModLogConfig
  alias Bolt.Paginator
  import Ecto.Query, only: [from: 2]
  alias Nostrum.Api
  alias Nostrum.Struct.Embed

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, []) do
    query = from(config in ModLogConfig, where: config.guild_id == ^msg.guild_id, select: config)

    case Repo.all(query) do
      [] ->
        response = "❌ modlog is not configured"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)

      config_rows ->
        pages =
          config_rows
          |> Enum.group_by(
            fn row -> row.event end,
            fn row -> row.channel_id end
          )
          |> Map.to_list()
          |> Stream.map(fn {event, channels} ->
            {event, Stream.map(channels, &"<##{&1}>")}
          end)
          |> Stream.map(fn {event, channels} ->
            "• `#{event}` is logged in #{Enum.join(channels, ", ")}"
          end)
          |> Stream.chunk_every(6)
          |> Enum.map(fn entry_chunk ->
            %Embed{
              description: Enum.join(entry_chunk, "\n")
            }
          end)

        base_embed = %Embed{
          title: "Mod log configuration",
          color: Constants.color_blue()
        }

        Paginator.paginate_over(msg, base_embed, pages)
    end
  end

  def command(msg, _args) do
    response = "🚫 this subcommand takes no arguments"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
