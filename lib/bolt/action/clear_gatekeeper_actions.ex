defmodule Bolt.Action.ClearGatekeeperActions do
  @behaviour Bolt.Action

  alias Bolt.Gatekeeper
  alias Bolt.ModLog
  import Ecto.Changeset
  use Ecto.Schema

  embedded_schema do
    field :kind, Ecto.Enum, values: [:join, :accept, :both]
  end

  def changeset(action, params) do
    action
    |> cast(params, [:kind])
  end

  def run(%__MODULE__{kind: :both}, %{guild_id: guild_id}) do
    {deleted_accepts, nil} = Gatekeeper.clear_actions(guild_id, :accept)
    {deleted_joins, nil} = Gatekeeper.clear_actions(guild_id, :join)

    ModLog.emit(
      guild_id,
      "AUTOMOD",
      "cleared #{deleted_accepts} accept, #{deleted_joins} join gatekeeper actions"
    )
  end

  def run(%__MODULE__{kind: kind}, %{guild_id: guild_id}) do
    {deleted, nil} = Gatekeeper.clear_actions(guild_id, kind)
    ModLog.emit(guild_id, "AUTOMOD", "cleared #{deleted} #{kind} gatekeeper actions")
  end

  defimpl String.Chars do
    alias Bolt.Action.ClearGatekeeperActions

    def to_string(%ClearGatekeeperActions{kind: :both}) do
      "delete gatekeeper actions for both accept and join"
    end

    def to_string(%ClearGatekeeperActions{kind: kind}) do
      "delete gatekeeper actions for #{kind}"
    end
  end
end
