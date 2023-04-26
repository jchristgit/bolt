defmodule Bolt.Cogs.Sudo.RRDStats do
  @moduledoc false

  alias Bolt.RRD
  alias Nostrum.Api

  def command(msg, []) do
    response =
      if RRD.enabled?() do
        {:ok, status, _pwd} = RRD.command("pwd")
        "📊 `#{status}`"
      else
        "📉 rrd is not configured..."
      end

    Api.create_message!(msg.channel_id, response)
  end

  def command(msg, _args) do
    response = "🚫 this subcommand accepts no arguments"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
