defmodule Bolt.Cogs.LastJoins do
  @moduledoc false

  @behaviour Nosedrum.TextCommand

  alias Bolt.{Constants, Helpers, Paginator, Parsers}
  alias Nosedrum.TextCommand.Predicates
  alias Nostrum.Api
  alias Nostrum.Cache.MemberCache
  alias Nostrum.Cache.UserCache
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Struct.User

  # The default number of members shown in the response.
  @default_shown 15

  # Members shown per page.
  @shown_per_page @default_shown

  # The maximum number of members shown in the response.
  @maximum_shown @shown_per_page * 9

  @impl true
  def usage, do: ["lastjoins [options...]"]

  @impl true
  def description,
    do: """
    Display the most recently joined members.
    Requires the `MANAGE_MESSAGES` permission.

    The result of this command can be customized with the following options:
    `--no-roles`: Display only new members without any roles
    `--roles`: Display only new members with any roles
    `--total`: The total amount of members to display, defaults to #{@default_shown}, maximum is #{@maximum_shown}

    Returned members will be sorted by their account creation time.

    **Examples**:
    ```rs
    // display the #{@default_shown} most recently joined members
    .lastjoins

    // display the 30 most recently joined members that do not have a role assigned
    .lastjoins --total 10 --no-roles
    ```
    """

  @impl true
  def predicates, do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_messages)]

  @impl true
  def parse_args(args) do
    OptionParser.parse(
      args,
      strict: [
        # --roles | --no-roles
        #   display only new members with or without roles
        roles: :boolean,
        # --total <int>
        #   the total amount of users to display
        total: :integer
      ]
    )
  end

  @impl true
  def command(msg, {options, _args, []}) do
    {limit, options} = Keyword.pop_first(options, :total, @default_shown)

    should_have_roles = Keyword.get(options, :roles, false)

    most_recent_members =
      msg.guild_id
      |> :bolt_member_qlc.recent_joins_q(should_have_roles)
      |> sort_by_limit(& &1.joined_at, sanitize_limit(limit))

    case most_recent_members do
      [] ->
        {:ok, _msg} = Api.create_message(msg.channel_id, "guild uncached or cache borked, sorry")

      members ->
        pages =
          members
          |> Stream.map(&format_member/1)
          |> Stream.chunk_every(@shown_per_page)
          |> Enum.map(&%Embed{fields: &1})

        base_page = %Embed{
          title: "Recently joined members",
          color: Constants.color_blue()
        }

        Paginator.paginate_over(msg, base_page, pages)
    end
  end

  def command(msg, {_parsed, _args, invalid}) when invalid != [] do
    invalid_args = Parsers.describe_invalid_args(invalid)

    {:ok, _msg} =
      Api.create_message(
        msg.channel_id,
        "🚫 unrecognized argument(s) or invalid value: #{invalid_args}"
      )
  end

  defp sanitize_limit(n) when n < 1, do: @default_shown
  defp sanitize_limit(n) when n > @maximum_shown, do: @maximum_shown
  defp sanitize_limit(n), do: n

  @spec format_member(Member.t()) :: Embed.Field.t()
  defp format_member(member) do
    joined_at_human = "<t:#{member.joined_at}:R>"
    total_roles = length(member.roles)
    user = UserCache.get!(member.user_id)

    %Embed.Field{
      name: User.full_name(user),
      value: """
      ID: `#{member.user_id}`
      Joined: #{joined_at_human}
      has #{total_roles} #{Helpers.pluralize(total_roles, "role", "roles")}
      """,
      inline: true
    }
  end

  defp sort_by_limit(query, key_fn, limit) do
    acc = {:gb_trees.empty(), 0, 0}

    reducer = fn item, {tree, smallest, size} ->
      case key_fn.(item) do
        key when key > smallest and size >= limit ->
          {_smallest, _value, new_tree} = :gb_trees.take_smallest(tree)
          {:gb_trees.insert(key, item, new_tree), key, size}

        key when size < limit ->
          {:gb_trees.insert(key, item, tree), key, size + 1}

        _key ->
          {tree, smallest, size}
      end
    end

    MemberCache.wrap_qlc(fn -> :qlc.fold(reducer, acc, query) end)
    |> elem(0)
    |> :gb_trees.to_list()
    |> Enum.reverse()
    |> Enum.map(&elem(&1, 1))
  end
end
