defmodule Bolt.Cogs.Sudo.Guilds do
  alias Bolt.Constants
  alias Bolt.Helpers
  alias Bolt.Paginator
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Field

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, []) do
    pages =
      GuildCache.all()
      |> Stream.map(
        &%Field{
          name: &1.name,
          value: """
          ID: `#{&1.id}`
          member count: `#{&1.member_count}`
          joined at: #{&1 |> DateTime.from_iso8601() |> Helpers.datetime_to_human()}
          """,
          inline: true
        }
      )
      |> Stream.chunk_every(6)
      |> Enum.map(
        &%Embed{
          fields: &1
        }
      )

    base_page = %Embed{
      title: "guilds in cache",
      color: Constants.color_blue()
    }

    Paginator.paginate_over(msg, base_page, pages)
  end

  def command(msg, _args) do
    response = "🚫 this subcommand accepts no arguments"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
