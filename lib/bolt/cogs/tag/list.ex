defmodule Bolt.Cogs.Tag.List do
  alias Bolt.Constants
  alias Bolt.Helpers
  alias Bolt.Paginator
  alias Bolt.Repo
  alias Bolt.Schema.Tag
  alias Nostrum.Struct.Embed
  import Ecto.Query, only: [from: 2]

  def command(msg) do
    pages = from(tag in Tag, where: tag.guild_id == ^msg.guild_id, select: tag.name)
            |> Repo.all()
            |> Stream.map(&"• #{Helpers.clean_content(&1)}")
            |> Stream.chunk_every(8)
            |> Enum.map(fn chunk -> %Embed{
              description: Enum.join(chunk, "\n")
            } end)

    base_page = %Embed{
      title: "Tags on this guild",
      color: Constants.color_blue()
    }

    Paginator.paginate_over(msg, base_page, pages)
  end
end
