defmodule Bolt.Cogs.Tag.Read do
  @moduledoc false

  alias Bolt.Constants
  alias Bolt.Helpers
  alias Bolt.Repo
  alias Bolt.Schema.Tag
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Footer
  alias Nostrum.Struct.{Message, User}
  import Ecto.Query, only: [from: 2]

  @spec command(Message.t(), [String.t()]) :: {:ok, Message.t()}
  def command(msg, args) when args != [] do
    name = Enum.join(args, " ")

    query = from(tag in Tag, where: tag.guild_id == ^msg.guild_id, select: tag)
    guild_tags = Repo.all(query)

    case Enum.find(guild_tags, &(String.downcase(&1.name) == String.downcase(name))) do
      nil ->
        close_matches =
          guild_tags
          |> Enum.filter(&(String.jaro_distance(&1.name, name) > 0.6))

        response =
          if close_matches == [] do
            "❌ no tag named exactly as or similarly to " <>
              "`#{Helpers.clean_content(name)}` found"
          else
            """
            ❌ no direct match found, but found the following close matches:
            #{close_matches |> Stream.map(&Helpers.clean_content(&1.name)) |> Enum.join(", ")}
            """
          end

        {:ok, _msg} = Api.create_message(msg.channel_id, response)

      matching_tag ->
        response = %Embed{
          title: matching_tag.name,
          description: matching_tag.content,
          timestamp: DateTime.to_iso8601(matching_tag.inserted_at),
          color: Constants.color_blue(),
          footer:
            (fn ->
               case Helpers.get_member(msg.guild_id, matching_tag.author_id) do
                 {:ok, member} ->
                   %Footer{
                     text: "Created by #{User.full_name(member.user)}",
                     icon_url: User.avatar_url(member.user)
                   }

                 {:error, _reason} ->
                   %Footer{
                     text: "Created by unknown user #{matching_tag.author_id}"
                   }
               end
             end).()
        }

        {:ok, _msg} = Api.create_message(msg.channel_id, embed: response)
    end
  end

  def command(msg, _args) do
    response =
      "ℹ usage: `tag <name:str>` or `tag <subcommand>" <>
        " [args...]`, see `help tag` for details"

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
