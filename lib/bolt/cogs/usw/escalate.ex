defmodule Bolt.Cogs.USW.Escalate do
  @moduledoc false

  alias Bolt.Repo
  alias Bolt.Schema.USWPunishmentConfig
  alias Nostrum.Api

  def command(msg, []) do
    response =
      case Repo.get(USWPunishmentConfig, msg.guild_id) do
        nil ->
          "🚫 USW punishment is not configured"

        %USWPunishmentConfig{escalate: escalate} ->
          "ℹ automatic punishment escalation is " <> if escalate, do: "enabled", else: "disabled"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, ["on"]) do
    response =
      case Repo.get(USWPunishmentConfig, msg.guild_id) do
        nil ->
          "🚫 USW punishment is not configured"

        config ->
          changeset = USWPunishmentConfig.changeset(config, %{escalate: true})
          {:ok, _updated_config} = Repo.update(changeset)
          "👌 automatic punishment escalation is now enabled"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, ["off"]) do
    response =
      case Repo.get(USWPunishmentConfig, msg.guild_id) do
        nil ->
          "🚫 USW punishment is not configured"

        config ->
          changeset = USWPunishmentConfig.changeset(config, %{escalate: false})
          {:ok, _updated_config} = Repo.update(changeset)
          "👌 automatic punishment escalation is now disabled"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
