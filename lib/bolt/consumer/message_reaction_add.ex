defmodule Bolt.Consumer.MessageReactionAdd do
  @moduledoc "Handles the `MESSAGE_REACTION_ADD` event."

  alias Bolt.Paginatorolt.Starboard
  alias Bolt.Starboard
  alias Nostrum.Struct.Event.MessageReactionAdd

  @spec handle(MessageReactionAdd.t()) :: :ok
  def handle(reaction) do
    GenServer.cast(Paginator, {:MESSAGE_REACTION_ADD, reaction})

    if reaction.guild_id != nil and reaction.emoji.name == "⭐" do
      Starboard.handle_star_reaction(reaction.guild_id, reaction.channel_id, reaction.message_id)
    end
  end
end
