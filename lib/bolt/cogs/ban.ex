defmodule Bolt.Cogs.Ban do
  @moduledoc false

  alias Bolt.Helpers
  alias Bolt.ModLog
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.User

  @spec command(
          Nostrum.Struct.Message.t(),
          [String.t() | String.t()]
        ) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, [user | reason_list]) do
    response =
      with reason <- Enum.join(reason_list, " "),
           {:ok, user_id, converted_user} <- Helpers.into_id(msg.guild_id, user),
           {:ok} <- Api.create_guild_ban(msg.guild_id, user_id, 7),
           infraction <- %{
             type: "ban",
             guild_id: msg.guild_id,
             user_id: user_id,
             actor_id: msg.author.id,
             reason: if(reason != "", do: reason, else: nil)
           },
           changeset <- Infraction.changeset(%Infraction{}, infraction),
           {:ok, _created_infraction} <- Repo.insert(changeset) do
        user_string =
          if converted_user != nil do
            "#{User.full_name(converted_user)} (`#{converted_user.id}`)"
          else
            "`#{user_id}`"
          end

        ModLog.emit(
          msg.guild_id,
          "INFRACTION_CREATE",
          "#{User.full_name(msg.author)} (`#{msg.author.id}`) banned #{user_string}" <>
            if(reason != "", do: " with reason `#{reason}`", else: "")
        )

        if reason != "" do
          "👌 banned #{user_string} with reason `#{reason}`"
        else
          "👌 banned #{user_string}"
        end
      else
        {:error, %{status_code: status, message: %{"message" => reason}}} ->
          "❌ API error: #{reason} (status code `#{status}`)"

        {:error, reason} ->
          "❌ error: #{Helpers.clean_content(reason)}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "🚫 invalid invocation, view `help ban` for details"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
