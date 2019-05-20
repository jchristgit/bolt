defmodule Bolt.Cogs.Infraction.Reason do
  @moduledoc false

  @behaviour Nosedrum.Command

  alias Nosedrum.Predicates
  alias Bolt.{Helpers, ModLog, Repo}
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.User

  @impl true
  def usage, do: ["infraction reason <id:int> <new_reason:str...>"]

  @impl true
  def description,
    do: """
    Updates the reason on the given infraction ID.
    Only the infraction creator can update its reason.
    Requires the `MANAGE_MESSAGES` permission.
    """

  @impl true
  def predicates,
    do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_messages)]

  @impl true
  def command(msg, [maybe_id | reason_list]) do
    new_reason = Enum.join(reason_list, " ")

    response =
      with {id, _rest} <- Integer.parse(maybe_id),
           infraction when infraction != nil <-
             Repo.get_by(Infraction, id: id, guild_id: msg.guild_id) do
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
      else
        nil ->
          "🚫 no infraction with the given ID found on this guild"

        :error ->
          "🚫 expected an integer (infraction ID to edit), but that is not a valid integer"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `infraction reason <id:int> <new_reason:str...>`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
