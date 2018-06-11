defmodule Bolt.Commands do
  alias Nostrum.Message

  case Application.get_env(:bolt, :default_prefix) do
    value when is_list(value) ->
      @prefixes value

    value when is_bitstring(value) ->
      @prefixes [value]

    value ->
      raise "unknown bot prefix format, must be tuple or string (got #{inspect value})"
  end

  @spec handle(Nostrum.Message.t()) :: :ok
  def handle(msg) do
    alias Nostrum.Api

    if String.starts_with?(msg.content, @prefixes) && !msg.author.bot do
      Api.create_message(msg.channel_id, "!congratulations, you are using a valid prefix")
    end
  end
end
