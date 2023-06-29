defmodule Bolt.Consumer.GuildAuditLogEntryCreate do
  @moduledoc "Handle new guild audit log events"

  alias Bolt.Constants
  alias Bolt.ModLog
  alias Nosedrum.MessageCache.Agent, as: MessageCache
  alias Nostrum.Cache.ChannelGuildMapping
  alias Nostrum.Snowflake
  alias Nostrum.Struct.Embed
  alias Nostrum.Struct.Guild.AuditLogEntry
  alias Nostrum.Struct.User
  alias Nostrum.UserCache
  import Bolt.Helpers, only: [datetime_to_human: 1]
  import Nostrum.Struct.Embed

  # https://discord.com/developers/docs/resources/audit-log#audit-log-entry-object-audit-log-events
  @type_message_delete 72

  @spec handle(AuditLogEntry.t()) :: any()
  def handle(%AuditLogEntry{
        action_type: @type_message_delete,
        user_id: censored_by,
        id: message_id,
        options: %{channel_id: channel_id}
      }) do
    guild_id = ChannelGuildMapping.get(channel_id)
    cached_message = MessageCache.get(guild_id, message_id, Bolt.MessageCache)

    unless cached_message == nil do
      embed = format_deleted_message(cached_message, censored_by)
      ModLog.emit_embed(guild_id, "MESSAGE_DELETE", embed)
    end
  end

  def handle(_entry) do
    :ok
  end

  defp format_deleted_message(cached_message, censored_by) do
    creation = Snowflake.creation_time(cached_message.id)

    %Embed{
      color: Constants.color_red(),
      description: cached_message.content,
      fields: [
        %Embed.Field{
          name: "Metadata",
          value: """
          Channel: <##{cached_message.channel_id}>
          Creation: #{datetime_to_human(creation)}
          Message ID: `#{cached_message.id}`
          """,
          inline: true
        }
      ],
      timestamp: DateTime.to_iso8601(creation)
    }
    |> add_author(cached_message)
    |> add_deleter(censored_by)
  end

  defp add_author(embed, cached_message) do
    case UserCache.get(cached_message.author.id) do
      {:ok, user} -> put_author(embed, User.full_name(user), nil, User.avatar_url(user))
      _error -> embed
    end
  end

  defp add_deleter(embed, censored_by) do
    case UserCache.get(censored_by) do
      {:ok, user} -> put_footer("Deleted by #{User.full_name(user)}", User.avatar_url(user))
      _error -> embed
    end
  end
end
