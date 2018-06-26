defmodule Bolt.Consumer do
  @moduledoc "Consumes events sent by the API gateway."

  alias Bolt.BotLog
  alias Bolt.Commander
  alias Bolt.Helpers
  alias Bolt.ModLog
  alias Bolt.Repo
  alias Bolt.Schema.SelfAssignableRoles
  alias Nostrum.Struct.Snowflake
  alias Nostrum.Struct.User
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

  def handle_event(
        {:MESSAGE_UPDATE,
         {%{
            content: content,
            guild_id: guild_id,
            author: author,
            channel_id: channel_id,
            id: msg_id
          }}, _ws_state}
      ) do
    if content != "" do
      jump_link = "https://discordapp.com/channels/#{guild_id}/#{channel_id}/#{msg_id}"

      ModLog.emit(
        guild_id,
        "MESSAGE_EDIT",
        """
        #{author.username}##{author.discriminator} (`#{author.id}`) edited their message (<#{
          jump_link
        }>) to:
        #{Helpers.clean_content(String.slice(content, 0..1800))}
        """
      )
    end
  end

  def handle_event(
        {:MESSAGE_DELETE, {%{channel_id: channel_id, guild_id: guild_id, id: msg_id}}, _ws_state}
      ) do
    ModLog.emit(
      guild_id,
      "MESSAGE_DELETE",
      "message with ID `#{msg_id}` deleted in <##{channel_id}>"
    )
  end

  def handle_event({:GUILD_MEMBER_ADD, {guild_id, member}, _ws_state}) do
    creation_datetime = Snowflake.creation_time(member.user.id)

    ModLog.emit(
      guild_id,
      "GUILD_MEMBER_ADD",
      "#{User.full_name(member.user)} (`#{member.user.id}`) has joined " <>
        "- account created #{Helpers.datetime_to_human(creation_datetime)}"
    )
  end

  def handle_event({:GUILD_MEMBER_REMOVE, {guild_id, member}, _ws_state}) do
    ModLog.emit(
      guild_id,
      "GUILD_MEMBER_REMOVE",
      "#{User.full_name(member.user)} (`#{member.user.id}`) has left"
    )
  end

  def handle_event({:MESSAGE_REACTION_ADD, {reaction}, _ws_state}) do
    GenServer.cast(Bolt.Paginator, {:MESSAGE_REACTION_ADD, reaction})
  end

  def handle_event({:GUILD_CREATE, {guild}, _ws_state}) do
    BotLog.emit(
      "📥 joined guild `#{guild.name}` (`#{guild.id}`)," <> " seeing #{guild.member_count} members"
    )
  end

  def handle_event({:GUILD_DELETE, {guild, _unavailable}, _ws_state}) do
    BotLog.emit("📤 left guild `#{guild.name}` (`#{guild.id}`)")
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

  def handle_event({:READY, {data}, _ws_state}) do
    BotLog.emit("⚡ Logged in and ready, seeing `#{length(data.guilds)}` guilds.")
  end

  @impl true
  def handle_event(_data) do
  end
end
