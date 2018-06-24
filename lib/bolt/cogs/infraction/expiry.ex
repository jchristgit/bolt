defmodule Bolt.Cogs.Infraction.Expiry do
  alias Bolt.Events.Handler
  alias Bolt.Helpers
  alias Bolt.Parsers
  alias Bolt.Repo
  alias Bolt.Schema.Event
  alias Bolt.Schema.Infraction

  def command(msg, maybe_id, new_expiry) do
    with infraction when infraction != nil <-
           Repo.get_by(Infraction, id: maybe_id, guild_id: msg.guild_id),
         {:ok, converted_expiry} <- Parsers.human_future_date(new_expiry, infraction.inserted_at),
         {:ok, event_id} <- Map.fetch(infraction.data, "event_id"),
         event when event != nil <- Repo.get(Event, event_id),
         {:ok, updated_event} <- Handler.update(event, %{timestamp: converted_expiry}),
         infraction_changeset <-
           Infraction.changeset(infraction, %{expires_at: converted_expiry}),
         {:ok, _updated_infraction} <- Repo.update(infraction_changeset) do
      "👌 infraction ##{infraction.id} now expires at #{
        Helpers.datetime_to_human(updated_event.timestamp)
      }"
    else
      nil -> "🚫 no infraction with ID `#{Helpers.clean_content(maybe_id)}` found"
      :error -> "🚫 there is no event associated with the given infraction"
      {:error, reason} -> "🚫 error: #{reason}"
    end
  end
end
