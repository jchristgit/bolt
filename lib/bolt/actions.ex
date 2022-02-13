defmodule Bolt.Actions do
  @moduledoc "Action group handling"

  alias Bolt.ModLog
  alias Bolt.Repo
  alias Bolt.Schema.Action
  alias Bolt.Schema.ActionGroup
  alias Ecto.Changeset
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.Message
  import Ecto.Query, only: [from: 2]

  @type context :: %{guild_id: Guild.id()}

  @spec create_guild_group(Guild.id(), String.t()) ::
          {:ok, ActionGroup.t()} | {:error, Changeset.t()}
  def create_guild_group(guild_id, name) do
    %ActionGroup{guild_id: guild_id, actions: []}
    |> ActionGroup.changeset(%{name: name})
    |> Repo.insert()
  end

  @spec get_guild_group(Guild.id(), String.t()) :: ActionGroup.t() | nil
  def get_guild_group(guild_id, name) do
    query =
      from(ag in ActionGroup,
        where: ag.guild_id == ^guild_id and ag.name == ^name,
        preload: :actions
      )

    Repo.one(query)
  end

  @spec get_guild_groups(Guild.id()) :: [ActionGroup.t()]
  def get_guild_groups(guild_id) do
    query = from(ag in ActionGroup, where: ag.guild_id == ^guild_id)
    Repo.all(query)
  end

  @spec add_guild_group_action(ActionGroup.t(), map()) ::
          {:ok, ActionGroup.t()} | {:error, Changeset.t()}
  @spec add_guild_group_action(Guild.id(), String.t(), map()) ::
          {:ok, ActionGroup.t()} | {:error, Changeset.t() | String.t()}
  def add_guild_group_action(group, action) do
    changeset = Action.changeset(%Action{}, action)
    set_guild_group_actions(group, group.actions ++ [changeset])
  end

  def add_guild_group_action(guild_id, name, action) do
    case get_guild_group(guild_id, name) do
      nil ->
        {:error, "unknown action group"}

      group ->
        add_guild_group_action(group, action)
    end
  end

  @spec set_guild_group_actions(ActionGroup.t(), [Action.t()]) ::
          {:ok, ActionGroup.t()} | {:error, Changeset.t()}
  @spec set_guild_group_actions(Guild.id(), String.t(), [Action.t()]) ::
          {:ok, ActionGroup.t()} | {:error, Changeset.t() | String.t()}
  def set_guild_group_actions(group, actions) do
    group
    |> ActionGroup.changeset()
    |> Changeset.put_assoc(:actions, actions)
    |> Repo.update()
  end

  def set_guild_group_actions(guild_id, name, actions) do
    case get_guild_group(guild_id, name) do
      nil ->
        {:error, "unknown action group"}

      group ->
        set_guild_group_actions(group, actions)
    end
  end

  @spec delete_guild_group(Guild.id(), String.t()) ::
          {:ok, ActionGroup.t()} | {:error, Changeset.t() | String.t()}
  def delete_guild_group(guild_id, name) do
    case get_guild_group(guild_id, name) do
      nil ->
        {:error, "unknown action group"}

      group ->
        Repo.delete(group)
    end
  end

  @spec build_context(Message.t()) :: context()
  def build_context(%Message{guild_id: guild_id}) do
    %{guild_id: guild_id}
  end

  @spec run_group(ActionGroup.t(), context()) :: any()
  def run_group(group, %{guild_id: guild_id} = context) do
    ModLog.emit(guild_id, "AUTOMOD", "starting action group `#{group.name}`")
    group_context = Map.put(context, :audit_log_reason, "action group run for group #{group.name}")
    Enum.map(group.actions, & &1.module.__struct__.run(&1.module, group_context))
    ModLog.emit(guild_id, "AUTOMOD", "finished run of action group `#{group.name}`")
  end
end
