defmodule Bolt.Consumer do
  @moduledoc "Consumes events sent by the API gateway."

  alias Bolt.Commander
  alias Bolt.Repo
  alias Bolt.Schema.SelfAssignableRoles
  use Nostrum.Consumer

  @spec start_link :: Supervisor.on_start()
  def start_link do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  @impl true
  @spec handle_event(Nostrum.Consumer.event()) :: any()
  def handle_event({:MESSAGE_CREATE, {msg}, _ws_state}) do
    Commander.handle_message(msg)
  end

  def handle_event({:MESSAGE_REACTION_ADD, {reaction}, _ws_state}) do
    GenServer.cast(Bolt.Paginator, {:MESSAGE_REACTION_ADD, reaction})
  end

  def handle_event({:GUILD_ROLE_DELETE, {guild_id, deleted_role}, _ws_state}) do
    case Repo.get(SelfAssignableRoles, guild_id) do
      %SelfAssignableRoles{roles: role_list} = sar_row ->
        if deleted_role.id in role_list do
          updated_roles = Enum.reject(role_list, &(&1 == deleted_role.id))
          changeset = SelfAssignableRoles.changeset(sar_row, %{roles: updated_roles})
          Repo.update(changeset)
        else
          :noop
        end

      _ ->
        :noop
    end
  end

  @impl true
  def handle_event(_event) do
    :noop
  end
end
