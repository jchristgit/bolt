defmodule Bolt.Cogs.USW.Status do
  @moduledoc false

  alias Bolt.Constants
  alias Bolt.Paginator
  alias Bolt.Repo
  alias Bolt.Schema.USWFilterConfig
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Field
  import Ecto.Query, only: [from: 2]

  def command(msg, []) do
    query =
      from(config in USWFilterConfig, where: config.guild_id == ^msg.guild_id, select: config)

    pages =
      query
      |> Repo.all()
      |> Stream.map(
        &%Field{
          name: "`#{&1.filter}`",
          value: """
          max: #{&1.count}
          per: #{&1.interval}s
          """,
          inline: true
        }
      )
      |> Stream.chunk_every(6)
      |> Enum.map(&%Embed{fields: &1})

    case pages do
      [] ->
        response = "🚫 no rules configured on this guild"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)

      _ ->
        base_embed = %Embed{
          title: "uncomplicated spam wall: status",
          color: Constants.color_blue()
        }

        Paginator.paginate_over(msg, base_embed, pages)
    end
  end

  def command(msg, _args) do
    response = "🚫 this subcommand accepts no arguments"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
