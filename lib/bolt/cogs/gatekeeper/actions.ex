defmodule Bolt.Cogs.GateKeeper.Actions do
  @moduledoc "Show configured actions on the guild."
  @behaviour Bolt.Command

  alias Bolt.Constants
  alias Bolt.Commander.Checks
  alias Bolt.Schema.{AcceptAction, JoinAction}
  alias Bolt.Repo
  alias Nostrum.Api
  alias Nostrum.Struct.{Channel, Embed, Message}
  import Ecto.Query, only: [from: 2]
  import Nostrum.Struct.Embed, only: [put_description: 2, put_field: 3]

  @impl true
  def usage, do: ["keeper actions [accept|join]"]

  @impl true
  def description,
    do: """
    Show actions that Gatekeeper is configured to execute when a member joins
    or runs accept. `accept` or `join` can be given to indicate that only actions
    of the given type should be shown. By default, all actions are shown.
    """

  @impl true
  def predicates, do: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]

  @spec format_entry({action :: String.t(), data :: map()}) :: String.t()
  defp format_entry({"add_role", %{"role_id" => role_id}}), do: "add role `#{role_id}`"
  defp format_entry({"remove_role", %{"role_id" => role_id}}), do: "remove role `#{role_id}`"

  defp format_entry({"send_guild", %{"channel_id" => channel_id, "template" => template}}),
    do: "send template ``#{template}`` to <##{channel_id}>"

  defp format_entry({"delete_invocation", _}), do: "delete the command invocation"

  @spec put_actions(
          embed :: Embed.t(),
          header :: String.t(),
          actions :: [AcceptAction.t() | JoinAction.t()]
        ) :: Embed.t()
  defp put_actions(embed, _header, []), do: embed

  defp put_actions(embed, header, actions),
    do:
      put_field(embed, header, actions |> Stream.map(&"• #{format_entry(&1)}") |> Enum.join("\n"))

  @spec put_empty_description(Embed.t(), String.t()) :: Embed.t()
  defp put_empty_description(%Embed{fields: nil} = embed, description),
    do: put_description(embed, description)

  defp put_empty_description(embed, _description), do: embed

  @spec display_entries([AcceptAction.t()], [JoinAction.t()], Channel.id()) ::
          {:ok, Message.t()} | Api.error()
  defp display_entries(accept_actions, join_actions, channel_id) do
    embed =
      %Embed{
        title: "configured gatekeeper actions",
        color: Constants.color_blue()
      }
      |> put_actions("accept actions", accept_actions)
      |> put_actions("join actions", join_actions)
      |> put_empty_description("Hmm, seems like there's nothing here yet.")

    {:ok, _msg} = Api.create_message(channel_id, embed: embed)
  end

  @impl true
  def command(msg, []) do
    accept_actions =
      from(action in AcceptAction,
        where: action.guild_id == ^msg.guild_id,
        select: {action.action, action.data}
      )
      |> Repo.all()

    join_actions =
      from(action in JoinAction,
        where: action.guild_id == ^msg.guild_id,
        select: {action.action, action.data}
      )
      |> Repo.all()

    display_entries(accept_actions, join_actions, msg.channel_id)
  end

  def command(msg, ["accept"]) do
    accept_actions =
      from(action in AcceptAction,
        where: action.guild_id == ^msg.guild_id,
        select: {action.action, action.data}
      )
      |> Repo.all()

    display_entries(accept_actions, [], msg.channel_id)
  end

  def command(msg, ["join"]) do
    join_actions =
      from(action in JoinAction,
        where: action.guild_id == ^msg.guild_id,
        select: {action.action, action.data}
      )
      |> Repo.all()

    display_entries([], join_actions, msg.channel_id)
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `#{usage()}`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
