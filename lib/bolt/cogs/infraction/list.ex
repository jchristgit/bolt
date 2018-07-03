defmodule Bolt.Cogs.Infraction.List do
  @moduledoc false

  alias Bolt.Cogs.Infraction.General
  alias Bolt.{Constants, Helpers, Paginator, Repo}
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.{Embed, Message}
  import Ecto.Query, only: [from: 2]

  @spec command(Message.t(), [String.t()]) :: {:ok, Message.t()}
  def command(msg, []) do
    query =
      from(
        infr in Infraction,
        where: infr.guild_id == ^msg.guild_id,
        order_by: [desc: infr.inserted_at],
        select: infr
      )

    queryset = Repo.all(query)

    base_embed = %Embed{
      title: "All infractions on this guild",
      color: Constants.color_blue()
    }

    formatted_entries =
      queryset
      |> Stream.map(fn infr ->
        "[`#{infr.id}`] #{General.emoji_for_type(infr.type)} on " <>
          "#{General.format_user(msg.guild_id, infr.user_id)} created #{
            Helpers.datetime_to_human(infr.inserted_at)
          }"
      end)
      |> Stream.chunk_every(6)
      |> Enum.map(fn entry_chunk ->
        %Embed{
          description: Enum.join(entry_chunk, "\n")
        }
      end)

    Paginator.paginate_over(msg, base_embed, formatted_entries)
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `infr list`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
