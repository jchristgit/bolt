defmodule Bolt.Cogs.Sudo.Log do
  @moduledoc false

  alias Bolt.ModLog
  alias Nostrum.Api

  @spec command(Nostrum.Struct.Message.t(), [String.t()]) :: {:ok, Nostrum.Struct.Message.t()}
  def command(msg, content_list) when content_list != [] do
    content = Enum.join(content_list, " ")
    startup_note = "⏲ distributing event, please wait"
    {:ok, startup_msg} = Api.create_message(msg.channel_id, startup_note)

    ModLog.emit(
      msg.guild_id,
      "BOT_UPDATE",
      content
    )

    response = "👌 event broadcasted to subscribed guilds"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
    Api.delete_message(startup_msg)
  end

  def command(msg, []) do
    response = "🚫 content to log must not be empty"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
