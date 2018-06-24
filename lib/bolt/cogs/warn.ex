defmodule Bolt.Cogs.Warn do
  alias Bolt.Converters
  alias Bolt.Helpers
  alias Bolt.Repo
  alias Bolt.Schema.Infraction
  alias Nostrum.Api
  alias Nostrum.Struct.User

  def command(msg, [user | reason_list]) do
    response =
      with reason when reason != "" <- Enum.join(reason_list, " "),
           {:ok, member} <- Converters.to_member(msg.guild_id, user),
           infraction <- %{
             type: "warning",
             guild_id: msg.guild_id,
             user_id: member.user.id,
             actor_id: msg.author.id,
             reason: reason
           },
           changeset <- Infraction.changeset(%Infraction{}, infraction),
           {:ok, _created_infraction} <- Repo.insert(changeset) do
        "👌 warned #{User.full_name(member.user)} (`#{Helpers.clean_content(reason)}`)"
      else
        "" ->
          "🚫 must provide a reason to warn the user for"

        {:error, reason} ->
          "❌ error: #{Helpers.clean_content(reason)}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _anything) do
    response = "🚫 command expects at least two arguments, see `help warn` for details"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
