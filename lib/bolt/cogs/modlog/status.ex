defmodule Bolt.Cogs.ModLog.Status do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.{Constants, Paginator, Repo}
  alias Bolt.Schema.ModLogConfig
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  import Ecto.Query, only: [from: 2]

  @impl true
  def usage, do: ["modlog status"]

  @impl true
  def description,
    do: """
    View the current configuration of the mod log.
    Shows which events are logged in which channel(s).
    Requires the MANAGE_MESSAGES permission.
    """

  @impl true
  def predicates,
    do: [&Bolt.Commander.Checks.guild_only/1, &Bolt.Commander.Checks.can_manage_messages?/1]

  @impl true
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
    response = "ℹ️ usage: `modlog status`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
