defmodule Bolt.Cogs.Infraction.Expiry do
  @moduledoc false

  alias Bolt.Events.Handler
  alias Bolt.Helpers
  alias Bolt.ModLog
  alias Bolt.Parsers
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Struct.User

  @spec command(
          Nostrum.Struct.Message.t(),
          String.t(),
          String.t()
        ) :: String.t()
  def command(msg, maybe_id, new_expiry) do
    with infraction when infraction != nil <-
           Repo.get_by(Infraction, id: maybe_id, guild_id: msg.guild_id),
         {:ok, converted_expiry} <-
           Parsers.human_future_date(
             new_expiry,
             infraction.inserted_at
           ),
         {:ok, updated_infraction} <- Handler.update(infraction, %{expires_at: converted_expiry}) do
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
        "🚫 there is no event associated with the given infraction"

      {:error, reason} ->
        "🚫 error: #{reason}"
    end
  end
end
