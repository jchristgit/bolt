defmodule Bolt.Cogs.Infraction.Reason do
  @moduledoc false

  alias Bolt.Repo
  alias Bolt.Schema.Infraction

  @spec get_response(
          Nostrum.Struct.Message.t(),
          integer,
          String.t()
        ) :: String.t()
  def get_response(msg, infraction_id, new_reason) do
    case Repo.get_by(Infraction, id: infraction_id, guild_id: msg.guild_id) do
      nil -> "❌ no infraction with the given ID found"

      infraction ->
        if msg.author.id != infraction.actor_id do
          "🚫 you need to be the infraction creator to do that"
        else
          changeset = Infraction.changeset(infraction, %{reason: new_reason})
          {:ok, updated_infraction} = Repo.update(changeset)

          "👌 updated infraction ##{updated_infraction.id}"
        end
    end
  end
end
