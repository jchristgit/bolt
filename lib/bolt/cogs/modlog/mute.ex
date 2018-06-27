defmodule Bolt.Cogs.ModLog.Mute do
  @moduledoc false

  alias Bolt.ModLog
  alias Bolt.ModLog.Silencer
  alias Nostrum.Api
  alias Nostrum.Struct.User

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
    response = "🚫 this subcommand accepts no arguments"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
