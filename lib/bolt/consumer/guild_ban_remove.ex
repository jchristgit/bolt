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
    do_regular_modlog(guild_id, user)

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

      [%Infraction{type: "ban"} = infraction] ->
        changeset = Infraction.changeset(infraction, %{active: false})
        updated_infraction = Repo.update!(changeset)

        ModLog.emit(
          guild_id,
          "INFRACTION_UPDATE",
          "#{user.username}##{user.discriminator} (`#{user.id}`) was manually unbanned while a" <>
            " ban was active, the infraction (##{updated_infraction.id})" <>
            " has been set to inactive."
        )

      [%Infraction{type: "tempban"} = infraction] ->
        {:ok, updated_infraction} = Handler.update(infraction, %{active: false})

        ModLog.emit(
          guild_id,
          "INFRACTION_UPDATE",
          "#{user.username}##{user.discriminator} (`#{user.id}`) was manually unbanned while a" <>
            " tempban was active, infraction (##{updated_infraction.id})" <>
            " has been set to inactive and bolt will not attempt to unban the user."
        )
    end
  end

  @spec do_regular_modlog(Guild.id(), %{
          avatar: User.avatar(),
          discriminator: User.discriminator(),
          id: User.id(),
          username: User.username()
        }) :: ModLog.on_emit()
  defp do_regular_modlog(guild_id, user) do
    ModLog.emit(
      guild_id,
      "GUILD_BAN_REMOVE",
      "#{user.username}##{user.discriminator} (`#{user.id}`) was unbanned"
    )
  end
end
