defmodule Bolt.Cogs.Clean do
  alias Bolt.Converters
  alias Bolt.Helpers
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

  @spec do_prune(Nostrum.Struct.Message.t(), [Nostrum.Struct.Snowflake.t()]) :: no_return()
  defp do_prune(msg, message_ids) do
    with {:ok} <- Api.bulk_delete_messages(msg.channel_id, message_ids) do
      {:ok} = Api.create_reaction(msg.channel_id, msg.id, "👌")
    else
      {:error, %{status_code: status, message: %{"message" => message}}} ->
        {:ok, _msg} =
          Api.create_message(
            msg.channel_id,
            "⚠ can't fetch channel messages or delete messages: #{message} (status #{status})"
          )
    end
  end

  @doc "Default invocation: `clean`"
  def command(msg, {[], [], []}) do
    case Api.get_channel_messages(msg.channel_id, 30) do
      {:ok, []} ->
        {:ok, _msg} =
          Api.create_message(
            msg.channel_id,
            "⚠ need `READ_MESSAGE_HISTORY` permission to do that"
          )

      {:ok, messages} ->
        do_prune(msg, Enum.map(messages, & &1.id))

      {:error, %{status_code: status, message: %{"message" => message}}} ->
        {:ok, _msg} =
          Api.create_message(
            msg.channel_id,
            "⚠ can't fetch messages: #{message} (status #{status})"
          )
    end
  end

  @doc "Invocation without options, but args provided: `clean <amount:int>`"
  def command(msg, {[], [maybe_amount | []], []}) do
    with {amount, _rest} <- Integer.parse(maybe_amount),
         {:ok, messages} when messages != [] <- Api.get_channel_messages(msg.channel_id, amount) do
      do_prune(msg, Enum.map(messages, & &1.id))
    else
      :error ->
        {:ok, _msg} =
          Api.create_message(
            msg.channel_id,
            "⚠ expected the message limit as the sole argument, but #{
              Helpers.clean_content(maybe_amount)
            } is not a valid number"
          )

      {:ok, []} ->
        {:ok, _msg} =
          Api.create_message(
            msg.channel_id,
            "⚠ couldn't find any messages to delete, does the bot have `READ_MESSAGE_HISTORY` permission?"
          )

      {:error, %{status_code: status, message: %{"message" => message}}} ->
        {:ok, _msg} =
          Api.create_message(
            msg.channel_id,
            "⚠ can't fetch messages: #{message} (status #{status})"
          )
    end
  end

  @doc "Invocation without options, but more than one arg provided: `clean 30 monoculus`"
  def command(msg, {[], [_maybe_amount | unrecognized_args], []}) do
    {:ok, _msg} =
      Api.create_message(
        msg.channel_id,
        "⚠ expected the message limit as the sole argument, but got `#{
          unrecognized_args
          |> Enum.join(" ")
          |> Helpers.clean_content()
        }` in addition to the expected limit"
      )
  end

  @doc "Invocation with valid options, but argv given, e.g. `clean --bots monoculus`"
  def command(msg, {options, args, []}) when options != [] and args != [] do
    {:ok, _msg} =
      Api.create_message(
        msg.channel_id,
        "⚠ expected either a sole limit argument or exact options, got both"
      )
  end

  @doc "Invocation with only options, e.g. `clean --bots --limit 40`"
  def command(msg, {options, [], []}) when options != [] do
    with {:ok, channel_id} <- parse_channel(msg, options),
         {:ok, message_ids} <- get_filtered_message_ids(msg, options, channel_id) do
      do_prune(msg, message_ids)
    else
      {:error, %{message: %{"limit" => errors}, status_code: status}} ->
        {:ok, _msg} =
          Api.create_message(
            msg.channel_id,
            "⚠ got status #{status} from the API, reason: #{Enum.join(errors, ", ")}"
          )

      {:error, reason} ->
        {:ok, _msg} = Api.create_message(msg.channel_id, "⚠ error: #{reason}")

      anything ->
        Api.create_message(msg.channel_id, "error: #{inspect(anything)}")
    end
  end

  @doc "Invocation with invalid args, e.g. `clean --whatever`"
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

    {:ok, _msg} =
      Api.create_message(
        msg.channel_id,
        "⚠ unrecognized argument(s) or invalid value: #{invalid_args}"
      )
  end

  @spec parse_channel(Nostrum.Struct.Message.t(), keyword()) ::
          {:ok, Nostrum.Struct.Snowflake.t()} | {:error, String.t()}
  defp parse_channel(msg, options) do
    case options[:channel] do
      nil ->
        {:ok, msg.channel_id}

      value ->
        case Converters.to_channel(msg.guild_id, value) do
          {:ok, channel} -> {:ok, channel.id}
          {:error, reason} -> {:error, "⚠ #{reason}"}
        end
    end
  end

  @spec parse_users(Nostrum.Struct.Message.t(), [String.t()]) ::
          {:ok, [Nostrum.Struct.Snowflake.t()]} | {:error, String.t()}
  defp parse_users(_msg, nil) do
    {:ok, []}
  end

  defp parse_users(msg, user) when is_bitstring(user) do
    case Integer.parse(user) do
      {value, _remainder} ->
        {:ok, [value]}

      :error ->
        case Converters.to_member(msg.guild_id, user) do
          {:ok, member} ->
            {:ok, [member.user.id]}

          {:error, _reason} ->
            {:error,
             "⚠ #{Helpers.clean_content(user)} is not a valid user (of this guild) or snowflake"}
        end
    end
  end

  defp parse_users(msg, users) when is_list(users) do
    valid_users =
      users
      |> Enum.map(fn maybe_user ->
        case Integer.parse(maybe_user) do
          {value, _remainder} ->
            value

          :error ->
            case Converters.to_member(msg.guild_id, maybe_user) do
              {:ok, member} -> member.id
              {:error, _reason} -> :error
            end
        end
      end)
      |> Enum.reject(&(&1 == :error))

    if Enum.empty?(valid_users) do
      {:error, "⚠ failed to parse any valid users"}
    else
      {:ok, valid_users}
    end
  end

  @spec bot_filter(Nostrum.Struct.Message.t(), keyword()) :: boolean()
  def bot_filter(msg, options) do
    # if `User.bot` is `nil`, then the user isn't a bot
    is_bot = case msg.author.bot do
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

  @spec get_filtered_message_ids(
          Nostrum.Struct.Snowflake.t(),
          keyword(),
          Nostrum.Struct.Snowflake.t()
        ) ::
          {:ok,
           [
             Nostrum.Struct.Snowflake.t()
           ]}
          | {:error, String.t()}
  defp get_filtered_message_ids(msg, options, channel_id) do
    limit = Keyword.get(options, :limit, 30)

    with {:ok, messages} when messages != [] <- Api.get_channel_messages(channel_id, limit + 1),
         {:ok, users} <- parse_users(msg, options[:user]) do
      to_delete =
        messages
        |> Enum.filter(&bot_filter(&1, options))
        # Don't delete the original command invocation message.
        |> Enum.reject(&(&1.id == msg.id))

      # Do we have any users we want to include specifically, instead of
      # scanning through all messages? If yes, only return messages
      # authored by the filtered users. otherwise, return all
      if !Enum.empty?(users) do
        {:ok, to_delete |> Enum.filter(&(&1.author.id in users)) |> Enum.map(& &1.id)}
      else
        {:ok, Enum.map(to_delete, & &1.id)}
      end
    else
      {:ok, []} ->
        {:error,
         "⚠ couldn't find any messages in the channel - does the bot have the `READ_MESSAGE_HISTORY` permission?"}

      {:error, %{status_code: status, message: %{"message" => message}}} ->
        {:error, "⚠ #{message} (status code #{status})"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
