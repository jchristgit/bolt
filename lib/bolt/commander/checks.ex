defmodule Bolt.Commander.Checks do
  alias Bolt.Constants
  alias Nostrum.Struct.Embed

  @doc """
  A function that checks whether
  the given message was sent on a
  Gulid. Note that messages retrieved
  via REST do not have the `guild_id`
  attribute set, and thus, will not
  be detected as guild messages properly.
  """
  @spec guild_only(Nostrum.Struct.Message.t()) :: Embed.t()
  def guild_only(msg) do
    case msg.guild_id do
      nil ->
        {:error,
         %Embed{
           title: "A required predicate for this command failed",
           description: "This command can only be used on guilds.",
           color: Constants.color_red()
         }}

      _guild_id ->
        {:ok, msg}
    end
  end
end
