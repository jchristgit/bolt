defmodule Bolt.Cogs.Filter.Show do
  @moduledoc false
  @behaviour Nosedrum.Command

  alias Nosedrum.Predicates
  alias Bolt.{Constants, Paginator, Repo}
  alias Bolt.Schema.FilteredWord
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  import Ecto.Query, only: [from: 2]

  @impl true
  def usage, do: ["filter show"]

  @impl true
  def description,
    do: """
    Show filtered tokens on this server.
    Requires the `MANAGE_GUILD` permission.
    """

  @impl true
  def predicates, do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_guild)]

  @impl true
  def command(msg, []) do
    query =
      from(token in FilteredWord,
        where: token.guild_id == ^msg.guild_id,
        select: token.word,
        order_by: token.word
      )

    base_embed = %Embed{
      title: "Filtered tokens",
      color: Constants.color_blue()
    }

    pages =
      query
      |> Repo.all()
      |> Stream.map(&"• #{&1}")
      |> Stream.chunk_every(15)
      |> Enum.map(
        &%Embed{
          description: Enum.join(&1, "\n")
        }
      )

    Paginator.paginate_over(msg, base_embed, pages)
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `#{List.first(usage())}`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
