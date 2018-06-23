defmodule Bolt.Cogs.Tag.Create do
  alias Bolt.Helpers
  alias Bolt.Repo
  alias Bolt.Schema.Tag
  alias Ecto.Changeset
  alias Nostrum.Api

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

    case Repo.insert(changeset) do
      {:ok, _created_tag} ->
        response_content = "👌 created the tag `#{Helpers.clean_content(name)}`"
        {:ok, _msg} = Api.create_message(msg.channel_id, response_content)

      {:error, changeset} ->
        header = "🚫 invalid arguments:"

          error_map = changeset
          |> Changeset.traverse_errors(fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

          response_content = Map.keys(error_map)
          |> Stream.map(&"#{&1} #{error_map[&1]}")
          |> Enum.join("\n")

        {:ok, _msg} = Api.create_message(msg.channel_id, "#{header}\n#{response_content}")
    end
  end
end
