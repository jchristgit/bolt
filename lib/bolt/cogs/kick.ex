defmodule Bolt.Cogs.Kick do
  @moduledoc false

  alias Bolt.Converters
  alias Bolt.Helpers
  alias Bolt.ModLog
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.User

  @spec command(
          Nostrum.Struct.Message.t(),
          [String.t() | [String.t()]]
        ) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, [user | reason_list]) do
    response =
      with reason <- Enum.join(reason_list, " "),
           {:ok, member} <- Converters.to_member(msg.guild_id, user),
           {:ok} <- Api.remove_guild_member(msg.guild_id, member.user.id),
           infraction <- %{
             type: "kick",
             guild_id: msg.guild_id,
             user_id: member.user.id,
             actor_id: msg.author.id,
             reason: if(reason != "", do: reason, else: nil)
           },
           changeset <- Infraction.changeset(%Infraction{}, infraction),
           {:ok, _created_infraction} <- Repo.insert(changeset) do
        ModLog.emit(
          msg.guild_id,
          "INFRACTION_CREATE",
          "#{User.full_name(msg.author)} (`#{msg.author.id}`) kicked" <>
            " #{User.full_name(member.user)} (`#{member.user.id}`)" <>
            if(reason != "", do: " with reason `#{reason}`", else: "")
        )

        response = "👌 kicked #{User.full_name(member.user)} (`#{member.user.id}`)"

        if reason != "" do
          response <> " with reason `#{Helpers.clean_content(reason)}`"
        else
          response
        end
      else
        {:error, %{status_code: status, message: %{"message" => reason}}} ->
          "❌ API error: #{reason} (status code `#{status}`)"

        {:error, reason} ->
          "❌ error: #{Helpers.clean_content(reason)}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
