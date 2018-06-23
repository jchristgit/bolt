defmodule Bolt.Cogs.Tag do
  alias Nostrum.Api

  def command(msg, ["create"]) do
    {:ok, _msg} = Api.create_message(msg.channel_id, "🚫 `create` subcommand expects at least two arguments")
  end

  def command(msg, ["create" | args]) do
    alias Bolt.Cogs.Tag.Create

    Create.command(msg, args)
  end

  def command(msg, ["delete"]) do
    {:ok, _msg} = Api.create_message(msg.channel_id, "🚫 `delete` subcommand expects the tag name as its sole argument")
  end

  def command(msg, ["delete" | tag_name]) do
    alias Bolt.Cogs.Tag.Delete

    Delete.command(msg, Enum.join(tag_name, " "))
  end

  def command(msg, ["list"]) do
    alias Bolt.Cogs.Tag.List

    List.command(msg)
  end

  def command(msg, ["list" | _args]) do
    {:ok, _msg} = Api.create_message(msg.channel_id, "🚫 `list` subcommand expects no arguments")
  end

  def command(msg, []) do
    response = "🚫 at least one argument (subcommand or tag to look up) is required"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, name_list) do
    alias Bolt.Cogs.Tag.Read

    name = Enum.join(name_list, " ")
    Read.command(msg, name)
  end
end
