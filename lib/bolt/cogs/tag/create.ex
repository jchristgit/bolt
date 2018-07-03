defmodule Bolt.Cogs.Tag.Create do
  @moduledoc false

  alias Bolt.{Helpers, Repo}
  alias Bolt.Schema.Tag
  alias Nostrum.Api
  alias Nostrum.Struct.Message

  @spec command(Message.t(), [String.t()]) :: {:ok, Message.t()}
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
