defmodule Bolt.Cogs.Sudo.Unload do
  @moduledoc "Unload a command, command group, or command alias."

  alias Bolt.Commander.Server
  alias Nostrum.Api
  alias Nostrum.Struct.User
  require Logger

  def command(msg, ["sudo"]) do
    {:ok, _msg} = Api.create_message(msg.channel_id, "❌ i'm afraid not")
  end

  def command(msg, [command_to_unload]) do
    reply =
      case :ets.lookup(:commands, command_to_unload) do
        [_result] ->
          Server.delete_entry(command_to_unload)
          Logger.info("`#{User.full_name(msg.author)}` unloaded command `#{command_to_unload}`.")
          "👌 `#{command_to_unload}` was unloaded"

        [] ->
          "🚫 no command or alias named `#{command_to_unload}` found"
      end

    {:ok, _msg} = Api.create_message(msg.channel_id, reply)
  end

  def command(msg, _args) do
    reply = "ℹ usage: `sudo unload <command_name:str>`"
    {:ok, _msg} = Api.create_message(msg.channel_id, reply)
  end
end
