defmodule Bolt.Consumer.GuildBanRemove do
  @moduledoc "Handles the `GUILD_BAN_REMOVE` event."

  alias Bolt.Events.Handler
  alias Bolt.{ModLog, Repo}
  alias Bolt.Schema.Infraction
  alias Nostrum.Struct.{Guild, User}
  import Ecto.Query, only: [from: 2]

  @spec handle(Guild.id(), %{
          guild_id: Guild.id(),
          user: %{
            avatar: User.avatar(),
            discriminator: User.discriminator(),
            id: User.id(),
            username: User.username()
          }
        }) :: :noop | ModLog.on_emit()
  def handle(guild_id, %{user: user}) do
    active_ban_query =
      from(
        infr in Infraction,
        where:
          infr.guild_id == ^guild_id and infr.user_id == ^user.id and infr.active and
            infr.type in ["tempban", "ban"],
        limit: 1,
        select: infr
      )

    case Repo.all(active_ban_query) do
      [] ->
        :noop

      [active_ban_or_tempban] ->
        {:ok, updated_infraction} = Handler.update(active_ban_or_tempban, %{active: false})

        ModLog.emit(
          guild_id,
          "INFRACTION_UPDATE",
          "#{user.username}##{user.discriminator} (`#{user.id}`) was manually unbanned while a" <>
            " #{updated_infraction.type} was active. The infraction (##{updated_infraction.id})" <>
            " has been set to inactive."
        )
    end
  end
end
