defmodule Bolt.Cogs.Infraction do
  @moduledoc false

  alias Nostrum.Api
  alias Nostrum.Struct.Message

  @spec command(Message.t(), [String.t()]) :: {:ok, Message.t()}
  def command(msg, ["detail" | args]) do
    alias Bolt.Cogs.Infraction.Detail

    Detail.command(msg, args)
  end

  def command(msg, ["expiry" | args]) do
    alias Bolt.Cogs.Infraction.Expiry

    Expiry.command(msg, args)
  end

  def command(msg, ["reason" | args]) do
    alias Bolt.Cogs.Infraction.Reason

    Reason.command(msg, args)
  end

  def command(msg, ["list" | args]) do
    alias Bolt.Cogs.Infraction.List

    List.command(msg, args)
  end

  def command(msg, ["user" | args]) do
    alias Bolt.Cogs.Infraction.User

    User.command(msg, args)
  end

  def command(msg, _anything) do
    response = "🚫 invalid subcommand, view `help infraction` for details"
    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end
end
