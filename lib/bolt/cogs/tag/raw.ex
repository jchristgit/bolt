defmodule Bolt.Cogs.Tag.Raw do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.Repo
  alias Bolt.Schema.Tag
  alias Nostrum.Api
  import Ecto.Query, only: [from: 2]

  @impl true
  def usage, do: ["tag raw <name:str...>"]

  @impl true
  def description, do: "Returns the raw contents of the tag named `name` as a file."

  @impl true
  def predicates, do: [&Checks.guild_only/1]

  @impl true
  def parse_args(args), do: Enum.join(args, " ")

  @doc since: "0.3.0"
  @impl true
  def command(msg, "") do
    response = "ℹ️ usage: `tag raw <name:str...>`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, name) do
    query =
      from(
        tag in Tag,
        where:
          tag.guild_id == ^msg.guild_id and
            fragment("LOWER(?)", tag.name) == ^String.downcase(name),
        select: tag
      )

    case Repo.all(query) do
      [] ->
        response = "🚫 no tag with that name found"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)

      [tag] ->
        file_map = %{
          name: "#{tag.name}.md",
          body: tag.content
        }

        {:ok, _msg} = Api.create_message(msg.channel_id, file: file_map)
    end
  end
end
