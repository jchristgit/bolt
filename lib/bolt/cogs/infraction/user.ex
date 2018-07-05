defmodule Bolt.Cogs.Infraction.User do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Cogs.Infraction.General
  alias Bolt.Commander.Checks
  alias Bolt.{Constants, Helpers, Paginator, Repo}
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  import Ecto.Query, only: [from: 2]

  @impl true
  def usage, do: ["infraction user <user:snowflake|member...>"]

  @impl true
  def description,
    do: """
    View all infractions for the given user.
    The user can be given as a snowflake if they are now longer present on this guild.
    Requires the `MANAGE_MESSAGES` permission.
    """

  @impl true
  def predicates,
    do: [&Checks.guild_only/1, &Checks.can_manage_messages?/1]

  @impl true
  def command(msg, args) when args != [] do
    user_text = Enum.join(args, " ")

    case Helpers.into_id(msg.guild_id, user_text) do
      {:ok, user_id, _maybe_user} ->
        query = from(i in Infraction, where: [guild_id: ^msg.guild_id, user_id: ^user_id])
        queryset = Repo.all(query)

        user_string = General.format_user(msg.guild_id, user_id)

        base_embed = %Embed{
          title: "infractions for #{user_string}",
          color: Constants.color_blue()
        }

        formatted_entries =
          queryset
          |> Stream.map(fn infr ->
            "[`#{infr.id}`] #{General.emoji_for_type(infr.type)} created #{
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

      {:error, reason} ->
        response = "🚫 #{Helpers.clean_content(reason)}"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `infraction user <user:snowflake|member...>`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
