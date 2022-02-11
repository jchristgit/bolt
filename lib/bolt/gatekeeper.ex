defmodule Bolt.Gatekeeper do
  @moduledoc "Member join & accept command handling"

  alias Bolt.Repo
  alias Bolt.Schema.AcceptAction
  alias Bolt.Schema.JoinAction
  import Ecto.Query, only: [from: 2]

  @spec clear_actions(Guild.id(), :accept | :join) :: {integer(), nil}
  def clear_actions(guild_id, :accept) do
    from(action in AcceptAction, where: action.guild_id == ^guild_id)
    |> Repo.delete_all()
  end

  def clear_actions(guild_id, :join) do
    from(action in JoinAction, where: action.guild_id == ^guild_id)
    |> Repo.delete_all()
  end
end
