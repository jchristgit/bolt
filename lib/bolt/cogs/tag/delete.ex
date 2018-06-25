defmodule Bolt.Cogs.Tag.Delete do
  @moduledoc false

  alias Bolt.Helpers
  alias Bolt.Repo
  alias Bolt.Schema.Tag
  alias Nostrum.Api

  @spec command(Nostrum.Struct.Message.t(), String.t()) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, tag_name) do
    case Repo.get_by(Tag, name: tag_name, guild_id: msg.guild_id) do
      nil ->
        response = "🚫 no tag named #{Helpers.clean_content(tag_name)} found on this guild"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)

      tag ->
        response =
          if msg.author.id != tag.author_id do
            "🚫 only the tag author can delete the tag"
          else
            case Repo.delete(tag) do
              {:ok, _deleted_tag} -> "👌 successfully deleted #{Helpers.clean_content(tag_name)}"
              {:error, _reason} -> "❌ couldn't delete the tag because of some weird error"
            end
          end

        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end
end
