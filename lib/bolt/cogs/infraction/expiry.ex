defmodule Bolt.Cogs.Infraction.Expiry do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.Events.Handler
  alias Bolt.{Helpers, ModLog, Parsers, Repo}
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.User
  require Logger

  @impl true
  def usage, do: ["infraction expiry <id:int> <expiry:duration>"]

  @impl true
  def description,
    do: """
    Update the expiration date of the given infraction ID.
    This is only applicable to timed (temporary) infractions that have not expired yet.
    Requires the `MANAGE_GUILD` permission.
    """

  @impl true
  def predicates,
    do: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]

  @impl true
  def command(msg, [maybe_id, new_expiry]) do
    response =
      with {id, _rest} <- Integer.parse(maybe_id),
           infraction when infraction != nil <-
             Repo.get_by(Infraction, id: id, guild_id: msg.guild_id),
           {:ok, converted_expiry} <-
             Parsers.human_future_date(
               new_expiry,
               infraction.inserted_at
             ),
           {:ok, updated_infraction} <-
             Handler.update(infraction, %{expires_at: converted_expiry}) do
        ModLog.emit(
          msg.guild_id,
          "INFRACTION_UPDATE",
          "#{User.full_name(msg.author)} (`#{msg.author.id}`) changed expiry for ##{infraction.id}" <>
            " to #{Helpers.datetime_to_human(updated_infraction.expires_at)}" <>
            ", was #{Helpers.datetime_to_human(infraction.expires_at)}"
        )

        "👌 infraction ##{infraction.id} now expires at #{
          Helpers.datetime_to_human(updated_infraction.expires_at)
        }"
      else
        nil ->
          "🚫 no infraction with ID `#{Helpers.clean_content(maybe_id)}` found"

        :error ->
          "🚫 expected an integer for the infraction ID, got something else"

        {:error, reason} when is_bitstring(reason) ->
          "❌ error: #{reason}"

        {:error, reason} ->
          Logger.error(fn ->
            "unexpected error in `infr expiry`: #{inspect(reason)}," <>
              " original message was '#{msg.content}'"
          end)

          "❌ unexpected error"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `infraction expiry <id:int> <expiry:duration>`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
