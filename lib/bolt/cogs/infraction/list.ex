defmodule Bolt.Cogs.Infraction.List do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Cogs.Infraction.General
  alias Bolt.{Constants, Helpers, Paginator, Repo}
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  import Ecto.Query, only: [from: 2]

  @impl true
  def usage, do: ["infraction list"]

  @impl true
  def description,
    do: """
    List all infractions on this guild.
    Requires the `MANAGE_MESSAGES` permission.
    """

  @impl true
  def predicates,
    do: [&Bolt.Commander.Checks.guild_only/1, &Bolt.Commander.Checks.can_manage_messages?/1]

  @impl true
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
