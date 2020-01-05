defmodule Bolt.Cogs.Infraction.List do
  @moduledoc false

  @behaviour Nosedrum.Command

  alias Bolt.Cogs.Infraction.General
  alias Bolt.Schema.Infraction
  alias Bolt.{Constants, Paginator, Repo}
  alias Nosedrum.Predicates
  alias Nostrum.Api
  alias Nostrum.Cache.Me
  alias Nostrum.Struct.Embed
  alias Timex.Duration
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
    do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_messages)]

  @impl true
  @spec parse_args([String.t()]) ::
          {OptionParser.parsed(), OptionParser.argv(), OptionParser.errors()}
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
    query =
      from(
        infr in Infraction,
        where: infr.guild_id == ^msg.guild_id,
        order_by: [desc: infr.inserted_at],
        select: infr
      )

    respond(query, msg)
  end

  @impl true
  def command(msg, {[automod: true], [], []}) do
    query =
      from(
        infr in Infraction,
        where: infr.guild_id == ^msg.guild_id and infr.actor_id == ^Me.get().id,
        order_by: [desc: infr.inserted_at],
        select: infr
      )

    respond(query, msg, "Infractions on this guild created by automod")
  end

  @impl true
  def command(msg, {[automod: false], [], []}) do
    query =
      from(
        infr in Infraction,
        where: infr.guild_id == ^msg.guild_id and infr.actor_id != ^Me.get().id,
        order_by: [desc: infr.inserted_at],
        select: infr
      )

    respond(query, msg, "Infractions on this guild excluding automod")
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

    pages =
      queryset
      |> Stream.map(fn infr ->
        %Embed.Field{
          name:
            "##{infr.id} #{General.emoji_for_type(infr.type)} #{
              if infr.expires_at != nil and infr.active, do: "(active)", else: ""
            }",
          value:
            """
            **User**: <@#{infr.user_id}>
            **Actor**: <@#{infr.actor_id}>
            **Creation**: #{Timex.from_now(infr.inserted_at)}
            """ <>
              if(
                infr.expires_at != nil,
                do: "**Duration**: #{format_duration(infr.inserted_at, infr.expires_at)}",
                else: ""
              ),
          inline: true
        }
      end)
      |> Stream.chunk_every(6)
      |> Enum.map(fn field_chunk ->
        %Embed{
          fields: field_chunk
        }
      end)

    Paginator.paginate_over(msg, base_embed, pages)
  end

  @spec format_duration(DateTime.t(), DateTime.t()) :: String.t()
  defp format_duration(creation, expiry) do
    creation
    |> DateTime.diff(expiry)
    |> Duration.from_seconds()
    |> Timex.format_duration(:humanized)
  end
end
