defmodule Bolt.Cogs.Tag.Create do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.{Helpers, Repo}
  alias Bolt.Schema.Tag
  alias Nostrum.Api

  @impl true
  def usage, do: ["tag create <name:str> <content:str...>"]

  @impl true
  def description,
    do: """
    Create a new tag with the given name and content. The name must be unique on this guild.

    **Examples**:
    ```rs
    // Create a tag named 'Music' with a link as content.
    .tag create Music www.youtube.com/watch?v=DLzxrzFCyOs

    // Create a tag spanning multiple words with a link as content.
    .tag create "Radio Ga Ga" www.youtube.com/watch?v=azdwsXLmrHE
    ```
    """

  @impl true
  def predicates, do: [&Checks.guild_only/1]

  @impl true
  def command(msg, ["", _content]) do
    {:ok, _msg} = Api.create_message(msg.channel_id, "🚫 tag name must not be empty")
  end

  def command(msg, [_name, ""]) do
    {:ok, _msg} = Api.create_message(msg.channel_id, "🚫 tag content must not be empty")
  end

  def command(msg, [name | content]) do
    new_tag = %{
      author_id: msg.author.id,
      guild_id: msg.guild_id,
      name: name,
      content: Enum.join(content, " ")
    }

    changeset = Tag.changeset(%Tag{}, new_tag)

    response =
      case Repo.insert(changeset) do
        {:ok, _created_tag} ->
          "👌 created the tag `#{Helpers.clean_content(name)}`"

        {:error, changeset} ->
          errors = Helpers.format_changeset_errors(changeset)
          "🚫 invalid arguments: \n#{Helpers.clean_content(errors)}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `tag create <name:str> <content:str...>`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
