defmodule Bolt.Cogs.ModLog.Unmute do
  @moduledoc false

  alias Bolt.ModLog
  alias Bolt.ModLog.Silencer
  alias Nostrum.Api
  alias Nostrum.Struct.User

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
    response = "🚫 this subcommand accepts no arguments"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
