defmodule Bolt.Consumer do
  @moduledoc "Consumes events sent by the API gateway."

  alias Bolt.Consumer.{
    GuildBanRemove,
    GuildCreate,
    GuildDelete,
    GuildMemberAdd,
    GuildMemberRemove,
    GuildMemberUpdate,
    GuildRoleDelete,
    MessageCreate,
    MessageDelete,
    MessageReactionAdd,
    MessageUpdate,
    Ready
  }

  use Nostrum.Consumer

  @spec start_link :: Supervisor.on_start()
  def start_link do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  @impl true
  @spec handle_event(Nostrum.Consumer.event()) :: any()
  def handle_event({:MESSAGE_CREATE, {msg}, _ws_state}) do
    MessageCreate.handle(msg)
  end

  def handle_event({:MESSAGE_UPDATE, {msg}, _ws_state}) do
    MessageUpdate.handle(msg)
  end

  def handle_event(
        {:MESSAGE_DELETE, {%{channel_id: channel_id, guild_id: guild_id, id: msg_id}}, _ws_state}
      ) do
    MessageDelete.handle(channel_id, guild_id, msg_id)
  end

  def handle_event({:GUILD_BAN_REMOVE, {guild_id, partial_member}, _ws_state}) do
    GuildBanRemove.handle(guild_id, partial_member)
  end

  def handle_event({:GUILD_MEMBER_ADD, {guild_id, member}, _ws_state}) do
    GuildMemberAdd.handle(guild_id, member)
  end

  def handle_event({:GUILD_MEMBER_REMOVE, {guild_id, member}, _ws_state}) do
    GuildMemberRemove.handle(guild_id, member)
  end

  def handle_event({:GUILD_MEMBER_UPDATE, {guild_id, old_member, new_member}, _ws_state}) do
    GuildMemberUpdate.handle(guild_id, old_member, new_member)
  end

  def handle_event({:MESSAGE_REACTION_ADD, {reaction}, _ws_state}) do
    MessageReactionAdd.handle(reaction)
  end

  def handle_event({:GUILD_CREATE, {guild}, _ws_state}) do
    GuildCreate.handle(guild)
  end

  def handle_event({:GUILD_DELETE, {guild, _unavailable}, _ws_state}) do
    GuildDelete.handle(guild)
  end

  def handle_event({:GUILD_ROLE_DELETE, {guild_id, deleted_role}, _ws_state}) do
    GuildRoleDelete.handle(guild_id, deleted_role)
  end

  def handle_event({:READY, {data}, _ws_state}) do
    Ready.handle(data)
  end

  def handle_event(_data) do
  end
end
