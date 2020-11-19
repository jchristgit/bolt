defmodule Bolt.Cogs.Ed do
  @moduledoc false

  @behaviour Nosedrum.Command

  alias Nostrum.Api

  @impl true
  def usage, do: ["ed [-GVhs] [-p string] [file]"]

  @impl true
  def description, do: "Ed is the standard text editor."

  @impl true
  def predicates, do: []

  @impl true
  def command(msg, _args) do
    {:ok, _msg} =
      Api.create_message(msg.channel_id, content: "?", message_reference: %{message_id: msg.id})
  end
end
