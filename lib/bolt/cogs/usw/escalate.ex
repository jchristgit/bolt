defmodule Bolt.Cogs.USW.Escalate do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.Repo
  alias Bolt.Schema.USWPunishmentConfig
  alias Nostrum.Api

  @impl true
  def usage, do: ["usw escalate [on|off]"]

  @impl true
  def description,
    do: """
    Toggles automatic punishment escalation.
    Use the command without any argument to show whether automatic punishment is currently enabled.
    Enable it using `on`, disable it again using `off`.

    Requires the `MANAGE_GUILD` permission.
    """

  @impl true
  def predicates,
    do: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]

  @impl true
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

  def command(msg, _args) do
    response = "ℹ️ usage: `usw escalate [on|off]`"
    {:ok, _msg} = Api.create_message(msg.channeL_id, response)
  end
end
