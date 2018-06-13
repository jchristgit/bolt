defmodule Bolt.Cogs.Echo do
  alias Nostrum.Api

  @doc """
  Greet the user specified with `name` with the given `content`.
  """
  def command("echo", msg, _args) do
    {:ok, msg} = Api.create_message(msg.channel_id, "I copy and pasted this code")
  end

  def command(_cmd, _msg, _args), do: :ok
end
