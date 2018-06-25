defmodule Bolt.Cogs.Infraction.Reason do
  @moduledoc false

  alias Bolt.Constants
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Struct.Embed

  @spec get_response(
          Nostrum.Struct.Message.t(),
          integer,
          String.t()
        ) :: Nostrum.Struct.Embed.t()
  def get_response(msg, infraction_id, new_reason) do
    case Repo.get_by(Infraction, id: infraction_id, guild_id: msg.guild_id) do
      nil ->
        %Embed{
          title: "Failed to look up infraction ##{infraction_id}",
          description: "No infraction with the given ID found. Does it exist on this guild?",
          color: Constants.color_red()
        }

      infraction ->
        if msg.author.id != infraction.actor_id do
          %Embed{
            title: "Not allowed to do that",
            description: "You need to be the creator of the infraction to do that.",
            color: Constants.color_red()
          }
        else
          changeset = Infraction.changeset(infraction, %{reason: new_reason})
          {:ok, updated_infraction} = Repo.update(changeset)

          %Embed{
            title: "Successfully updated infraction ##{updated_infraction.id}",
            description: "Use `infr detail #{updated_infraction.id}` to view it.",
            color: Constants.color_green()
          }
        end
    end
  end
end
