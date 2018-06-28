defmodule Bolt.Cogs.Temprole do
  @moduledoc false

  alias Bolt.Converters
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
  def command(msg, [user, role, duration | reason_list]) do
    response =
      with reason <- Enum.join(reason_list, " "),
           {:ok, member} <- Converters.to_member(msg.guild_id, user),
           {:ok, role} <- Converters.to_role(msg.guild_id, role),
           query <-
             from(
               infr in Infraction,
               where:
                 infr.active and infr.user_id == ^member.user.id and
                   infr.guild_id == ^msg.guild_id and infr.type == "temprole" and
                   fragment("data->'role_id' = ?", ^role.id),
               limit: 1,
               select: {infr.id, infr.expires_at}
             ),
           [] <- Repo.all(query),
           {:ok, expiry} <- Parsers.human_future_date(duration),
           {:ok} <-
             Api.modify_guild_member(
               msg.guild_id,
               member.user.id,
               roles: Enum.uniq(member.roles ++ [role.id])
             ),
           infraction_map <- %{
             type: "temprole",
             guild_id: msg.guild_id,
             user_id: member.user.id,
             actor_id: msg.author.id,
             reason: if(reason != "", do: reason, else: nil),
             expires_at: expiry,
             data: %{
               "role_id" => role.id
             }
           },
           {:ok, _created_infraction} <- Handler.create(infraction_map) do
        ModLog.emit(
          msg.guild_id,
          "INFRACTION_CREATE",
          "#{User.full_name(msg.author)} (`#{msg.author.id}`) applied temporary role" <>
            " #{role.name} (`#{role.id}`) to #{User.full_name(member.user)}" <>
            " (`#{member.user.id}`) until #{Helpers.datetime_to_human(expiry)}" <>
            if(reason != "", do: " with reason `#{reason}`", else: "")
        )

        response =
          "👌 temporary role `#{role.name}` applied to " <>
            "#{User.full_name(member.user)} until #{Helpers.datetime_to_human(expiry)}"

        if reason != "" do
          response <> " with reason `#{Helpers.clean_content(reason)}`"
        else
          response
        end
      else
        {:error, %{message: %{"message" => reason}, status_code: status}} ->
          "❌ API error: #{reason} (status code `#{status}`)"

        {:error, %{message: :timeout}} ->
          "❌ API request timed out, please retry"

        {:error, reason} ->
          "❌ error: #{Helpers.clean_content(reason)}"

        [{existing_id, existing_expiry}] ->
          "❌ there already is an infraction applying that role under ID ##{existing_id}" <>
            " which will expire on #{Helpers.datetime_to_human(existing_expiry)}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _incorrect_args) do
    response = "🚫 failed to parse arguments, check `help temprole` for details"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
