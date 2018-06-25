defmodule Bolt.Cogs.Role do
  @moduledoc false

  alias Nostrum.Api

  def command(msg, ["allow"]) do
    {:ok, _msg} =
      Api.create_message(
        msg.channel_id,
        "🚫 `allow` subcommand expects a role as its sole argument"
      )
  end

  def command(msg, ["allow" | role_name_list]) do
    alias Bolt.Cogs.Role.Allow

    role_name = Enum.join(role_name_list, " ")
    Allow.command(msg, role_name)
  end

  def command(msg, ["deny"]) do
    {:ok, _msg} =
      Api.create_message(
        msg.channel_id,
        "🚫 `deny` subcommand expects a role as its sole argument"
      )
  end

  def command(msg, ["deny" | role_name_list]) do
    alias Bolt.Cogs.Role.Deny

    role_name = Enum.join(role_name_list, " ")
    Deny.command(msg, role_name)
  end

  def command(msg, _) do
    {:ok, _msg} =
      Api.create_message(msg.channel_id, "🚫 unknown subcommand, see `help role` for information")
  end
end
