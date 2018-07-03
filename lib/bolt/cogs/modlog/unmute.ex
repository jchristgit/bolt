defmodule Bolt.Cogs.ModLog.Unmute do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.ModLog
  alias Bolt.ModLog.Silencer
  alias Nostrum.Api
  alias Nostrum.Struct.User

  @impl true
  def usage, do: ["modlog mute"]

  @impl true
  def description,
    do: """
    Unmuet the mod log after it was muted previously.
    Requires the `MANAGE_GUILD` permission.
    """

  @impl true
  def predicates,
    do: [&Bolt.Commander.Checks.guild_only/1, &Bolt.Commander.Checks.can_manage_guild?/1]

  @impl true
  def command(msg, []) do
    response =
      if Silencer.is_silenced?(msg.guild_id) do
        :ok = Silencer.remove(msg.guild_id)

        ModLog.emit(
          msg.guild_id,
          "CONFIG_UPDATE",
          "#{User.full_name(msg.author)} (`#{msg.author.id}`) has unmuted the modlog"
        )

        "👌 mod log is no longer silenced"
      else
        "🚫 the mod log is not silenced"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "ℹ️ usage: `modlog unmute`"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
