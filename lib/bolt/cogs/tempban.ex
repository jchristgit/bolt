defmodule Bolt.Cogs.Tempban do
  @moduledoc false

  alias Bolt.Events.Handler
  alias Bolt.Helpers
  alias Bolt.ModLog
  alias Bolt.Parsers
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.User
  import Ecto.Query, only: [from: 2]

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, [user, duration | reason_list]) do
    response =
      with reason <- Enum.join(reason_list, " "),
           {:ok, user_id, converted_user} <- Helpers.into_id(msg.guild_id, user),
           {:ok, expiry} <- Parsers.human_future_date(duration),
           query <-
             from(
               infr in Infraction,
               where:
                 infr.active and infr.user_id == ^user_id and infr.guild_id == ^msg.guild_id and
                   infr.type in ^["tempban", "ban"],
               limit: 1,
               select: {infr.id, infr.expires_at}
             ),
           [] <- Repo.all(query),
           {:ok} <- Api.create_guild_ban(msg.guild_id, user_id, 7),
           infraction_map <- %{
             type: "tempban",
             guild_id: msg.guild_id,
             user_id: user_id,
             actor_id: msg.author.id,
             reason: if(reason != "", do: reason, else: nil),
             expires_at: expiry
           },
           {:ok, _created_infraction} <- Handler.create(infraction_map) do
        user_string =
          if converted_user == nil do
            "`#{user_id}`"
          else
            "#{User.full_name(converted_user)} (`#{user_id}`)"
          end

        ModLog.emit(
          msg.guild_id,
          "INFRACTION_CREATE",
          "#{User.full_name(msg.author)} (`#{msg.author.id}`) temporarily banned" <>
            " #{user_string} until #{Helpers.datetime_to_human(expiry)}" <>
            if(reason != "", do: " with reason `#{Helpers.clean_content(reason)}`", else: "")
        )

        response =
          "👌 temporarily banned #{user_string} until #{Helpers.datetime_to_human(expiry)}"

        if reason != "" do
          response <> " with reason `#{Helpers.clean_content(reason)}`"
        else
          response
        end
      else
        {:error, %{status_code: status, message: %{"message" => reason}}} ->
          "❌ API error: #{reason} (status code `#{status}`)"

        {:error, reason} ->
          "❌ error: #{reason}"

        [{existing_id, existing_expiry}] ->
          case existing_expiry do
            nil ->
              "❌ that member is already permanently banned according to my records"

            _expiry ->
              "❌ there already is a tempban for that member under ID" <>
                " ##{existing_id} which will expire on " <>
                Helpers.datetime_to_human(existing_expiry)
          end
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "🚫 invalid arguments, check `help tempban` for details"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
