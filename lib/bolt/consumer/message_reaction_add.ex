defmodule Bolt.Consumer.MessageReactionAdd do
  @moduledoc "Handles the `MESSAGE_REACTION_ADD` event."

  alias Bolt.Paginator
  alias Nostrum.Struct.Message.Reaction

  @spec handle(Reaction.t()) :: :ok
  def handle(reaction) do
    GenServer.cast(Paginator, {:MESSAGE_REACTION_ADD, reaction})
  end
end
