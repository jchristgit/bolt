defmodule Bolt.Cogs.ModLog.Mute do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.ModLog
  alias Bolt.ModLog.Silencer
  alias Nostrum.Api
  alias Nostrum.Struct.User

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
    do: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]

  @impl true
  def command(msg, []) do
    response =
      if Silencer.is_silenced?(msg.guild_id) do
        "🚫 the mod log is already silenced"
      else
        ModLog.emit(
          msg.guild_id,
          "CONFIG_UPDATE",
          "#{User.full_name(msg.author)} (`#{msg.author.id}`) has muted the modlog"
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
