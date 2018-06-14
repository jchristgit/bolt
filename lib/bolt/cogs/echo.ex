defmodule Bolt.Cogs.Echo do
  alias Nostrum.Api

  @doc """
  Greet the user specified with `name` with the given `content`.
  """
  def command(msg, args) do
    {:ok, _msg} =
      Api.create_message(msg.channel_id, "I copy and pasted this code, args: #{inspect(args)}")
  end
end
