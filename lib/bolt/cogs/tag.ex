defmodule Bolt.Cogs.Tag do
  alias Nostrum.Api

  def command(msg, ["create"]) do
    {:ok, _msg} = Api.create_message(msg.channel_id, "🚫 `create` subcommand expects at least two arguments")
  end

  def command(msg, ["create" | args]) do
    alias Bolt.Cogs.Tag.Create

    Create.command(msg, args)
  end

  def command(msg, name_list) do
    alias Bolt.Cogs.Tag.Read

    name = Enum.join(name_list, " ")
    Read.command(msg, name)
  end
end
