defmodule Bolt.Cogs.Clean do
  @moduledoc false

  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.{Converters, ErrorFormatters, Helpers, ModLog}
  alias Nostrum.Api
  alias Nostrum.Struct.{Message, Snowflake, User}

  @impl true
  def usage, do: ["clean <amount:int>", "clean <options...>"]

  @impl true
  def description,
    do: """
    Cleanup messages. The execution of this command can be customized with the following options:
    `--bots`: Only clean messages authored by bots
    `--no-bots`: Do not clean any messages authored by bots
    `--limit <amount:int>`: Specify the limit of messages to delete
    `--channel <channel:textchannel>`: The channel to delete messages in
    `--user <user:snowflake|user>`: Only delete messages by this user, can be specified multiple times
    `--content <content:str>`: Only delete messages containing `content`

    **Examples**:
    ```rs
    // delete 60 messages in the current channel
    clean 60

    // delete up to 10 messages by
    // bots in the current channel
    clean --bots --limit 10

    // delete up to 30 messages sent
    // by 197177484792299522 in the #fsharp channel
    clean --user 197177484792299522 --channel #fsharp

    // delete up to 50 messages containing
    // "lol no generics" in the #golang channel
    clean --content "lol no generics" --channel #golang --limit 50
    ```
    """

  @impl true
  def predicates,
    do: [&Checks.guild_only/1, &Checks.can_manage_messages?/1]

  @impl true
  def parse_args(args) do
    OptionParser.parse(
      args,
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

  @spec do_prune(Message.t(), [Snowflake.t()]) :: no_return()
  defp do_prune(msg, message_ids) do
    message_ids = Enum.reject(message_ids, &(&1 == msg.id))

    with {:ok} <- Api.bulk_delete_messages(msg.channel_id, message_ids) do
      {:ok} = Api.create_reaction(msg.channel_id, msg.id, "👌")
    else
      {:error, %{status_code: status, message: %{"message" => message}}} ->
        {:ok, _msg} =
          Api.create_message(
            msg.channel_id,
            "❌ can't fetch channel messages or delete messages: #{message} (status #{status})"
          )
    end
  end

  @spec log_deleted(Message.t(), [Message.t()]) :: ModLog.on_emit()
  defp log_deleted(invocation_message, messages) do
    log_content =
      messages
      |> Stream.map(
        &"#{String.pad_leading(&1.author.username, 20)}##{&1.author.discriminator}: #{&1.content}"
      )
      |> Enum.reverse()
      |> Enum.join("\n")

    ModLog.emit(
      invocation_message.guild_id,
      "MESSAGE_CLEAN",
      "#{User.full_name(invocation_message.author)} (`#{invocation_message.author.id}`) deleted" <>
        " #{length(messages)} messages in <##{invocation_message.channel_id}>",
      file: %{
        name: "deleted_messages.log",
        body: log_content
      }
    )
  end

  @impl true
  @spec command(
          Message.t(),
          {OptionParser.parsed(), OptionParser.argv(), OptionParser.errors()}
        ) :: {:ok, Message.t()}
  def command(msg, {[], [], []}) do
    response =
      "ℹ️ usage: `#{List.first(usage())}` or `#{List.last(usage())}`, " <>
        "see `help clean` for options"

    {:ok, _msg} = Api.create_message(msg.channel_id, response)
  end

  def command(msg, {[], [maybe_amount | []], []}) do
    with {amount, _rest} <- Integer.parse(maybe_amount),
         {:ok, messages} when messages != [] <-
           Api.get_channel_messages(
             msg.channel_id,
             amount
           ) do
      do_prune(msg, Enum.map(messages, & &1.id))
      log_deleted(msg, messages)
    else
      :error ->
        {:ok, _msg} =
          Api.create_message(
            msg.channel_id,
            "🚫 expected the message limit as the sole argument, but #{
              Helpers.clean_content(maybe_amount)
            } is not a valid number"
          )

      {:ok, []} ->
        {:ok, _msg} =
          Api.create_message(
            msg.channel_id,
            "❌ couldn't find any messages to delete, does the bot have `READ_MESSAGE_HISTORY` permission?"
          )

      error ->
        response = ErrorFormatters.fmt(msg, error)
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end

  def command(msg, {[], [_maybe_amount | unrecognized_args], []}) do
    {:ok, _msg} =
      Api.create_message(
        msg.channel_id,
        "🚫 expected the message limit as the sole argument, but got `#{
          unrecognized_args
          |> Enum.join(" ")
          |> Helpers.clean_content()
        }` in addition to the expected limit"
      )
  end

  def command(msg, {options, args, []}) when options != [] and args != [] do
    {:ok, _msg} =
      Api.create_message(
        msg.channel_id,
        "🚫 expected either a sole limit argument or exact options, got both"
      )
  end

  def command(msg, {options, [], []}) when options != [] do
    with {:ok, channel_id} <- parse_channel(msg, options),
         {:ok, messages} <-
           get_filtered_messages(
             msg,
             options,
             channel_id
           ) do
      do_prune(msg, Enum.map(messages, & &1.id))
      log_deleted(msg, messages)
    else
      {:error, %{message: %{"limit" => errors}, status_code: status}} ->
        {:ok, _msg} =
          Api.create_message(
            msg.channel_id,
            "❌ API error: #{Enum.join(errors, ", ")} (status `#{status}`)"
          )

      error ->
        response = ErrorFormatters.fmt(msg, error)
        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end

  def command(msg, {_parsed, _args, invalid}) when invalid != [] do
    invalid_args =
      invalid
      |> Stream.map(fn {option_name, value} ->
        case value do
          nil -> "`#{option_name}`"
          val -> "`#{option_name}` (set to `#{val}`)"
        end
      end)
      |> Enum.join(", ")
      |> Helpers.clean_content()

    {:ok, _msg} =
      Api.create_message(
        msg.channel_id,
        "🚫 unrecognized argument(s) or invalid value: #{invalid_args}"
      )
  end

  @spec parse_channel(Message.t(), keyword()) :: {:ok, Snowflake.t()} | {:error, String.t()}
  defp parse_channel(msg, options) do
    case options[:channel] do
      nil ->
        {:ok, msg.channel_id}

      value ->
        case Converters.to_channel(msg.guild_id, value) do
          {:ok, channel} -> {:ok, channel.id}
          error -> error
        end
    end
  end

  @spec snowflake_or_name_to_snowflake(
          Message.t(),
          String.t()
        ) :: Snowflake.t() | :error
  defp snowflake_or_name_to_snowflake(msg, maybe_user) do
    case Integer.parse(maybe_user) do
      {value, _remainder} ->
        value

      :error ->
        case Converters.to_member(msg.guild_id, maybe_user) do
          {:ok, member} -> member.user.id
          {:error, _reason} -> :error
        end
    end
  end

  @spec parse_users(
          Message.t(),
          String.t() | [String.t()]
        ) :: {:ok, [Snowflake.t()]} | {:error, String.t()}
  def parse_users(_msg, nil) do
    {:ok, []}
  end

  def parse_users(msg, user) when is_bitstring(user) do
    case snowflake_or_name_to_snowflake(msg, user) do
      :error ->
        {:error,
         "🚫 `#{Helpers.clean_content(user)}` is not a valid user (of this guild) or snowflake"}

      snowflake ->
        {:ok, [snowflake]}
    end
  end

  def parse_users(msg, users) when is_list(users) do
    valid_users =
      users
      |> Enum.map(&snowflake_or_name_to_snowflake(msg, &1))
      |> Enum.reject(&(&1 == :error))

    if Enum.empty?(valid_users) do
      {:error, "❌ failed to parse any valid users"}
    else
      {:ok, valid_users}
    end
  end

  @spec bot_filter(Message.t(), keyword()) :: boolean()
  def bot_filter(msg, options) do
    # if `User.bot` is `nil`, then the user isn't a bot
    is_bot =
      case msg.author.bot do
        nil -> false
        val -> val
      end

    cond do
      # no bot filter specified, passthrough
      options[:bots] == nil ->
        true

      # --bots specified: filter out non-bots
      options[:bots] ->
        is_bot

      # --no-bots specified: filter out bots
      !options[:bots] ->
        !is_bot
    end
  end

  @spec get_filtered_messages(
          Message.t(),
          keyword(),
          Channel.id()
        ) ::
          {:ok,
           [
             Message.t()
           ]}
          | {:error, String.t()}
  defp get_filtered_messages(msg, options, channel_id) do
    limit = Keyword.get(options, :limit, 30)

    # Since the command invocation is excluded from the prune,
    # add one to the limit to ensure the `limit` option is consistent.
    channel_messages = Api.get_channel_messages(channel_id, limit + 1)

    with {:ok, messages} when messages != [] <- channel_messages,
         {:ok, users} <- parse_users(msg, options[:user]) do
      to_delete =
        messages
        |> Enum.filter(&bot_filter(&1, options))
        # Don't delete the original command invocation message.
        |> Enum.reject(&(&1.id == msg.id))

      # Was the `content` option given?
      # If yes, only delete messages with the given content.
      to_delete =
        if options[:content] != nil do
          Enum.filter(
            to_delete,
            &String.contains?(&1.content, options[:content])
          )
        else
          to_delete
        end

      # Do we have any users we want to include specifically, instead of
      # scanning through all messages? If yes, only return messages
      # authored by the filtered users. otherwise, return all
      if Enum.empty?(users) do
        {:ok, to_delete}
      else
        {
          :ok,
          to_delete
          |> Enum.filter(&(&1.author.id in users))
        }
      end
    else
      {:ok, []} ->
        {:error,
         "❌ couldn't find any messages in the channel - does the bot have the `READ_MESSAGE_HISTORY` permission?"}

      error ->
        {:error, ErrorFormatters.fmt(msg, error)}
    end
  end
end
