defmodule Bolt.Cogs.Infraction.Reason do
  @moduledoc false

  alias Bolt.Helpers
  alias Bolt.ModLog
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Struct.User

  @spec get_response(
          Nostrum.Struct.Message.t(),
          integer,
          String.t()
        ) :: String.t()
  def get_response(msg, infraction_id, new_reason) do
    case Repo.get_by(Infraction, id: infraction_id, guild_id: msg.guild_id) do
      nil ->
        "❌ no infraction with the given ID found"

      infraction ->
        if msg.author.id != infraction.actor_id do
          "🚫 you need to be the infraction creator to do that"
        else
          changeset = Infraction.changeset(infraction, %{reason: new_reason})
          {:ok, updated_infraction} = Repo.update(changeset)

          ModLog.emit(
            msg.guild_id,
            "INFRACTION_UPDATE",
            "#{User.full_name(msg.author)} (`#{msg.author.id}`) " <>
              if(
                infraction.reason == nil,
                do:
                  "added the reason `#{Helpers.clean_content(new_reason)}` to ##{infraction.id}",
                else:
                  "updated the reason of infraction ##{infraction.id} to" <>
                    "`#{Helpers.clean_content(new_reason)}`, was" <>
                    "`#{Helpers.clean_content(infraction.reason)}`"
              )
          )

          "👌 updated infraction ##{updated_infraction.id}"
        end
    end
  end
end
