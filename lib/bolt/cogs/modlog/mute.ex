defmodule Bolt.Cogs.ModLog.Mute do
  @moduledoc false

  @behaviour Nosedrum.Command

  alias Bolt.Humanizer
  alias Bolt.ModLog
  alias Bolt.ModLog.Silencer
  alias Nosedrum.Predicates
  alias Nostrum.Api

  @impl true
  def usage, do: ["modlog mute"]

  @impl true
  def description,
    do: """
    Temporarily mute the mod log.
    Unlike the other mod log configuration, this will NOT persist across bolt reboots (although rare).
    Use `modlog unset all` if you want to stop logging events permanently, and use this for temporary mutes.
    Requires the `MANAGE_GUILD` permission.
    """

  @impl true
  def predicates,
    do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_guild)]

  @impl true
  def command(msg, []) do
    response =
      if Silencer.is_silenced?(msg.guild_id) do
        "🚫 the mod log is already silenced"
      else
        ModLog.emit(
          msg.guild_id,
          "CONFIG_UPDATE",
          "#{Humanizer.human_user(msg.author)}  has muted the modlog"
        )

        :ok = Silencer.add(msg.guild_id)
        "👌 mod log is now silenced (non-persistent)"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `modlog mute`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
