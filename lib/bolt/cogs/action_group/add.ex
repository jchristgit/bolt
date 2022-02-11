defmodule Bolt.Cogs.ActionGroup.Add do
  @moduledoc false

  @behaviour Nosedrum.Command

  alias Bolt.Action
  alias Bolt.Actions
  alias Bolt.ErrorFormatters
  alias Bolt.ModLog
  alias Nosedrum.Predicates
  alias Nostrum.Api
  alias Bolt.Schema.Action, as: SchemaAction
  import Bolt.Humanizer, only: [human_user: 1]

  @impl true
  def usage,
    do: [
      "ag add <name:str> clear_gatekeeper_actions [accept|join|both]",
      "ag add <name:str> delete_invites"
    ]

  @impl true
  def description,
    do: """
    Add an action to an action group.

    - `clear_gatekeeper_actions` deletes all actions for gatekeeper for the selected chain
    - `delete_invites` deletes all invites for the guild, excluding vanity URL

    Requires the `MANAGE_GUILD` permission.
    """

  @impl true
  def predicates,
    do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_guild)]

  @impl true
  def command(msg, [name, "delete_invites" = function]) do
    action = %{module: %{__type__: function}}
    add_action(msg, name, action, function)
  end

  def command(msg, [name, "clear_gatekeeper_actions" = function, kind]) do
    action = %{module: %{__type__: function, kind: kind}}
    add_action(msg, name, action, function)
  end

  def command(msg, _args) do
    response = "ℹ️ see help for usage details"
    Api.create_message!(msg.channel_id, response)
  end

  defp add_action(msg, name, action, action_name) do
    response =
      case Actions.add_guild_group_action(msg.guild_id, name, action) do
        {:ok, _action} ->
          ModLog.emit(
            msg.guild_id,
            "CONFIG_UPDATE",
            "#{human_user(msg.author)} added `#{action_name}` to action group `#{name}`"
          )

          "👌 this action group will now #{action.module}"

        error ->
          ErrorFormatters.fmt(msg, error)
      end

    Api.create_message!(msg.channel_id, response)
  end
end
