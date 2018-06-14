defmodule Bolt.Cogs.Clean do
  alias Nostrum.Api

  @spec parse([String.t()]) :: {OptionParser.parsed(), OptionParser.argv(), OptionParser.errors()}
  def parse(arguments) do
    OptionParser.parse(
      arguments,
      strict: [
        # --bots | --no-bots
        #   clean only bot messages, or exclude bot messages from cleaning
        bots: :boolean,
        # --channel <channel:textchannel>
        #   clean in the given channel instead of the current one
        channel: :string,
        # --limit <limit:int>
        #   clean at most `limit` messages
        limit: :integer,
        # --user <user:snowflake|user>
        #   clean only messages by `user`, can be specified multiple times
        user: [:string, :keep],
        # --content <str>
        #   clean only messages containing `content` (case-insensitive)
        content: :string
      ]
    )
  end

  @doc "Default invocation: `clean`"
  def command(msg, {[], [], []}) do
    with {:ok, messages} <- Api.get_channel_messages(msg.channel_id, 20),
         {:ok} <- Api.bulk_delete_messages(msg.channel_id, Stream.map(messages, & &1.id)) do
      Api.create_reaction(msg.channel_id, msg.id, "👌")
    else
      {:error, %{status_code: status, message: %{"message" => message}}} ->
        {:ok, _msg} =
          Api.create_message(
            msg.channel_id,
            "⚠ can't fetch channel messages or delete messages: #{message} (status #{status})"
          )
    end
  end
end
