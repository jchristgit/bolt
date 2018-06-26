defmodule Bolt.Cogs.USW.Punish do
  @moduledoc false

  alias Bolt.Converters
  alias Bolt.Helpers
  alias Bolt.Parsers
  alias Bolt.Repo
  alias Bolt.Schema.USWPunishmentConfig
  alias Nostrum.Api

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, ["temprole", role, duration]) do
    response =
      with {:ok, role} <- Converters.to_role(msg.guild_id, role),
           {:ok, expiry} <- Parsers.human_future_date(duration),
           total_seconds <- DateTime.diff(expiry, DateTime.utc_now()),
           new_config <- %{
             guild_id: msg.guild_id,
             duration: total_seconds,
             punishment: "TEMPROLE",
             data: %{
               "role_id" => role.id
             }
           },
           changeset <- USWPunishmentConfig.changeset(%USWPunishmentConfig{}, new_config),
           {:ok, _config} <-
             Repo.insert(
               changeset,
               conflict_target: [:guild_id],
               on_conflict: :replace_all
             ) do
        "👌 punishment is now applying temporary role `#{role.name}` for" <>
          " #{total_seconds} seconds"
      else
        {:error, reason} ->
          "🚫 error: #{Helpers.clean_content(reason)}"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
