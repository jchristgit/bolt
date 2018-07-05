defmodule Bolt.Cogs.Infraction.List do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Cogs.Infraction.General
  alias Bolt.{Constants, Helpers, Paginator, Repo}
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Cache.Me
  alias Nostrum.Struct.Embed
  import Ecto.Query, only: [from: 2]

  @impl true
  def usage, do: ["infraction list"]

  @impl true
  def description,
    do: """
    List all infractions on this guild.
    Requires the `MANAGE_MESSAGES` permission.

    When `--no-automod` is given (e.g. `infr list --no-automod`), does not show any infractions created by the automod.
    When `--automod` is given, only shows infractions created by the automod.
    """

  @impl true
  def predicates,
    do: [&Bolt.Commander.Checks.guild_only/1, &Bolt.Commander.Checks.can_manage_messages?/1]

  @impl true
  @spec parse_args([String.t()]) :: {OptionParser.parsed(), OptionParser.argv(), OptionParser.errors()}
  def parse_args(args) do
    OptionParser.parse(
      args,
      strict: [
        automod: :boolean
      ]
    )
  end

  @impl true
  def command(msg, {[], [], []}) do
      from(
        infr in Infraction,
        where: infr.guild_id == ^msg.guild_id,
        order_by: [desc: infr.inserted_at],
        select: infr
      )
      |> respond(msg)
  end

  @impl true
  def command(msg, {[automod: true], [], []}) do
      from(
        infr in Infraction,
        where: infr.guild_id == ^msg.guild_id and infr.actor_id == ^Me.get().id,
        order_by: [desc: infr.inserted_at],
        select: infr
      )
      |> respond(msg, "Infractions on this guild created by automod")
  end

  @impl true
  def command(msg, {[automod: false], [], []}) do
      from(
        infr in Infraction,
        where: infr.guild_id == ^msg.guild_id and infr.actor_id != ^Me.get().id,
        order_by: [desc: infr.inserted_at],
        select: infr
      )
      |> respond(msg, "Infractions on this guild excluding automod")
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `infr list [--automod|--no-automod]`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  @spec respond(Ecto.Query.t(), Message.t(), String.t()) :: {:ok, Message.t()}
  defp respond(query, msg, title \\ "All infractions on this guild") do
    queryset = Repo.all(query)

    base_embed = %Embed{
      title: title,
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
end
