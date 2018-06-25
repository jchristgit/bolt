defmodule Bolt.Cogs.Tempban do
  @moduledoc false

  alias Bolt.Events.Handler
  alias Bolt.Helpers
  alias Bolt.Parsers
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.User

  def command(msg, [user, duration | reason_list]) do
    response =
      with reason <- Enum.join(reason_list, " "),
           {:ok, user_id, converted_user} <- Helpers.into_id(msg.guild_id, user),
           {:ok, expiry} <- Parsers.human_future_date(duration),
           {:ok} <- Api.create_guild_ban(msg.guild_id, user_id, 7),
           {:ok, event} <-
             Handler.create(%{
               timestamp: expiry,
               event: "UNBAN_MEMBER",
               data: %{
                 "guild_id" => msg.guild_id,
                 "user_id" => user_id
               }
             }),
           infraction <- %{
             type: "tempban",
             guild_id: msg.guild_id,
             user_id: user_id,
             actor_id: msg.author.id,
             reason: if(reason != "", do: reason, else: nil),
             expires_at: expiry,
             data: %{
               "event_id" => event.id
             }
           },
           changeset <- Infraction.changeset(%Infraction{}, infraction),
           {:ok, _created_infraction} <- Repo.insert(changeset) do
        user_string =
          if converted_user == nil do
            "`#{user_id}`"
          else
            "#{User.full_name(converted_user)} (`#{user_id}`)"
          end

        response =
          "👌 temporarily banned #{user_string} until #{Helpers.datetime_to_human(expiry)}"

        if reason != "" do
          response <> " (`#{Helpers.clean_content(reason)}`)"
        else
          response
        end
      else
        {:error, %{status_code: status, message: %{"message" => reason}}} ->
          "🚫 API error: #{reason} (status code `#{status}`)"

        {:error, reason} ->
          "🚫 error: #{reason}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "🚫 invalid arguments, check `help tempban` for details"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
