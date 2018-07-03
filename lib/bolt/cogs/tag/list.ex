defmodule Bolt.Cogs.Tag.List do
  @moduledoc false

  alias Bolt.{Constants, Paginator, Repo}
  alias Bolt.Schema.Tag
  alias Nostrum.Api
  alias Nostrum.Struct.{Embed, Message}
  import Ecto.Query, only: [from: 2]

  @spec command(Message.t(), [String.t()]) :: {:ok, Message.t()} | reference()
  def command(msg, []) do
    query = from(tag in Tag, where: tag.guild_id == ^msg.guild_id, select: tag.name)

    pages =
      query
      |> Repo.all()
      |> Stream.map(&"• #{&1}")
      |> Stream.chunk_every(8)
      |> Enum.map(fn chunk ->
        %Embed{
          description: Enum.join(chunk, "\n")
        }
      end)

    base_page = %Embed{
      title: "Tags on this guild",
      color: Constants.color_blue()
    }

    Paginator.paginate_over(msg, base_page, pages)
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `tag list`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
