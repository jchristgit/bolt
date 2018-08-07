defmodule Bolt.Cogs.InRole do
  @moduledoc "Shows members in the given role."

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.{Constants, Converters, ErrorFormatters, Paginator}
  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.{Embed, User}

  @impl true
  def usage, do: ["inrole <role:role>"]

  @impl true
  def description,
    do: """
    Show members in the given role. The converter is case-insensitive.

    **Example**:
    ```rs
    // Show members in the 'Muted' role
    .inrole muted
    ```
    """

  @impl true
  def predicates, do: [&Checks.guild_only/1]

  @impl true
  def parse_args(args), do: Enum.join(args, " ")

  @impl true
  def command(msg, "") do
    response = "ℹ️ usage: `inrole <role:role...>`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, role_string) do
    with {:ok, role} <- Converters.to_role(msg.guild_id, role_string, true),
         {:ok, members} <-
           GuildCache.select(
             msg.guild_id,
             fn guild ->
               guild.members
               |> Map.values()
               |> Enum.filter(&(role.id in &1.roles))
             end
           ) do
      base_embed = %Embed{
        title: "Members with role `#{role.name}` (`#{length(members)}` total)",
        color: Constants.color_blue()
      }

      pages =
        members
        |> Enum.sort_by(&String.downcase(&1.user.username))
        |> Stream.map(&"#{User.full_name(&1.user)} (#{User.mention(&1.user)})")
        |> Stream.chunk_every(25)
        |> Enum.map(fn mention_chunk ->
          %Embed{
            description: Enum.join(mention_chunk, ", ")
          }
        end)

      Paginator.paginate_over(msg, base_embed, pages)
    else
      error ->
        response = ErrorFormatters.fmt(msg, error)
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end
end
