defmodule Bolt.Consumer.GuildMemberUpdate do
  @moduledoc "Handles the `GUILD_MEMBER_UPDATE` event."

  alias Bolt.{
    ModLog,
    Repo
  }

  alias Bolt.Events.Handler
  alias Bolt.Schema.Infraction

  alias Nostrum.Struct.{
    Guild,
    User
  }

  alias Nostrum.Struct.Guild.Member
  import Ecto.Query, only: [from: 2]

  @spec handle(Guild.id(), Member.t(), Member.t()) :: ModLog.on_emit()
  def handle(guild_id, old_member, new_member) do
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
end
