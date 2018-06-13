defmodule Bolt.Commands.Echo do
  alias Nostrum.Api

  # @on_definition {Bolt.Commander, :on_def}

  @doc """
  Greet the user specified with `name` with the given `content`.
  """
  def command("echo", msg, _args) do
    {:ok, msg} = Api.create_message(msg.channel_id, "I copy and pasted this code")
  end
end
