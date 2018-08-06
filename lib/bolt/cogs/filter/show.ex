defmodule Bolt.Cogs.Filter.Show do
  @moduledoc false
  @behaviour Bolt.Command

  alias Bolt.Constants
  alias Bolt.Commander.Checks
  alias Bolt.{Paginator, Repo}
  alias Bolt.Schema.FilteredWord
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  import Ecto.Query, only: [from: 2]

  @impl true
  def usage, do: ["filter show"]

  @impl true
  def description, do: """
  Show filtered tokens on this server.
  Requires the `MANAGE_GUILD` permission.
  """

  @impl true
  def predicates, do: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]

  @impl true
  def command(msg, []) do
    query =
      from(token in FilteredWord, where: token.guild_id == ^msg.guild_id, select: token.word)

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
