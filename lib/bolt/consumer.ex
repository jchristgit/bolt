defmodule Bolt.Consumer do
  @moduledoc "Consumes events sent by the API gateway."

  alias Bolt.BotLog
  alias Bolt.Commander
  alias Bolt.Constants
  alias Bolt.Events.Handler
  alias Bolt.Helpers
  alias Bolt.MessageCache
  alias Bolt.ModLog
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Bolt.Schema.SelfAssignableRoles
  alias Bolt.USW
  import Ecto.Query, only: [from: 2]
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Embed.Author
  alias Nostrum.Struct.Embed.Field
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
    unless msg.author.bot do
      Commander.handle_message(msg)
      MessageCache.consume(msg)
      USW.apply(msg)
    end
  end

  def handle_event(
        {:MESSAGE_UPDATE,
         {%{
            content: content,
            guild_id: guild_id,
            author: author,
            channel_id: channel_id,
            id: msg_id
          } = msg}, _ws_state}
      ) do
    if content != "" do
      from_cache = MessageCache.get(channel_id, msg_id)

      embed = %Embed{
        author: %Author{
          name: "#{author.username}##{author.discriminator} (#{author.id})"
          # FIXME: Once the nostrum bug with users being sent as raw maps
          #        in the event payload is fixed, edit this back in, and change
          #        the user#discrim building above to User.full_name/1.
          # icon_url: User.avatar_url(author)
        },
        color: Constants.color_blue(),
        url: "https://discordapp.com/channels/#{guild_id}/#{channel_id}/#{msg_id}",
        fields: [
          %Field{
            name: "Metadata",
            value: """
            Channel: <##{channel_id}>
            Message ID: #{msg_id}
            """,
            inline: true
          },
          %Field{
            name: "Old content",
            value:
              (fn ->
                 content =
                   if(from_cache != nil, do: from_cache.content, else: "*unknown, not in cache*")

                 String.slice(content, 0..1020)
               end).(),
            inline: true
          },
          %Field{
            name: "Updated content",
            value: String.slice(content, 0..1020),
            inline: true
          }
        ]
      }

      ModLog.emit(
        guild_id,
        "MESSAGE_EDIT",
        embed
      )

      MessageCache.update(msg)
    end
  end

  def handle_event(
        {:MESSAGE_DELETE, {%{channel_id: channel_id, guild_id: guild_id, id: msg_id}}, _ws_state}
      ) do
    content =
      case MessageCache.get(channel_id, msg_id) do
        nil -> "*unknown, message not in cache*"
        cached_msg -> String.slice(cached_msg.content, 0..1020)
      end

    embed = %Embed{
      color: Constants.color_red(),
      fields: [
        %Field{
          name: "Metadata",
          value: """
          Channel: <##{channel_id}>
          Creation: #{msg_id |> Snowflake.creation_time() |> Helpers.datetime_to_human()}
          Message ID: #{msg_id}
          """,
          inline: true
        },
        %Field{
          name: "Content",
          value: content,
          inline: true
        }
      ]
    }

    ModLog.emit(
      guild_id,
      "MESSAGE_DELETE",
      embed
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

    query =
      from(
        infr in Infraction,
        where:
          infr.guild_id == ^guild_id and infr.user_id == ^member.user.id and
            infr.type == "temprole" and infr.expires_at > ^DateTime.utc_now(),
        select: infr
      )

    case Repo.all(query) do
      [] ->
        :noop

      infractions ->
        infractions
        |> Enum.each(fn temprole_infraction ->
          with {:ok} <-
                 Api.add_guild_member_role(
                   guild_id,
                   member.user.id,
                   temprole_infraction.data["role_id"]
                 ) do
            ModLog.emit(
              guild_id,
              "INFRACTION_EVENTS",
              "member #{User.full_name(member.user)} (`#{member.user.id}`) with active temprole" <>
                " (`#{temprole_infraction.data["role_id"]}`) rejoined, temporary role was reapplied"
            )
          else
            {:error, %{message: %{"message" => reason}}} ->
              ModLog.emit(
                guild_id,
                "INFRACTION_EVENTS",
                "member #{User.full_name(member.user)} (`#{member.user.id}`) with active temprole" <>
                  " rejoined, but failed to reapply role: `#{reason}`"
              )
          end
        end)
    end
  end

  def handle_event({:GUILD_MEMBER_REMOVE, {guild_id, member}, _ws_state}) do
    ModLog.emit(
      guild_id,
      "GUILD_MEMBER_REMOVE",
      "#{User.full_name(member.user)} (`#{member.user.id}`) has left"
    )
  end

  def handle_event({:GUILD_MEMBER_UPDATE, {guild_id, old_member, new_member}, _ws_state}) do
    with role_diff <- List.myers_difference(old_member.roles, new_member.roles),
         removed_roles when removed_roles != [] <- Keyword.get(role_diff, :del, []),
         removed_role_id <- List.first(removed_roles),
         query <-
           from(
             infr in Infraction,
             where:
               infr.guild_id == ^guild_id and infr.user_id == ^new_member.user.id and infr.active and
                 fragment("data->'role_id' = ?", ^removed_role_id) and infr.type == "temprole",
             limit: 1,
             select: infr
           ),
         active_temproles when active_temproles != [] <- Repo.all(query),
         active_temprole <- List.first(active_temproles),
         {:ok, _updated_infraction} <- Handler.update(active_temprole, %{active: false}) do
      ModLog.emit(
        guild_id,
        "INFRACTION_UPDATE",
        "role `#{removed_role_id}` was manually removed from #{User.full_name(new_member.user)}" <>
          " (`#{new_member.user.id}`) while a temprole was active (##{active_temprole.id})" <>
          ", the infraction is now inactive and bolt will not attempt to remove the role"
      )
    else
      _err -> :ignored
    end
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

          ModLog.emit(
            guild_id,
            "CONFIG_UPDATE",
            "self-assignable role `#{deleted_role.name}` was deleted and" <>
              " automatically removed from the self-assignable roles"
          )
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
