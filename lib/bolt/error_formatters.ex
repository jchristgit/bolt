defmodule Bolt.ErrorFormatters do
  @moduledoc "Pretty-prints various errors that commands produce."

  alias Bolt.BotLog
  alias Ecto.Changeset
  alias Nostrum.Error.ApiError
  require Logger

  @spec fmt(Message.t(), term()) :: String.t()
  def fmt(msg, error)

  def fmt(_msg, reason) when is_bitstring(reason), do: "❌ error: #{reason}"

  def fmt(_msg, {:error, reason}) when is_bitstring(reason), do: "❌ error: #{reason}"

  def fmt(_msg, {:error, %Changeset{} = changeset}) do
    # doesn't work for nested changeset errors
    error_map =
      changeset
      |> Changeset.traverse_errors(fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)

    description =
      error_map
      |> Map.keys()
      |> Stream.map(&"#{&1} #{error_map[&1]}")
      |> Enum.join(", ")

    "❌ database error: #{description}"
  end

  def fmt(_msg, {:error, %ApiError{status_code: status, response: %{message: reason}}}) do
    "❌ API error: #{reason} (status code `#{status}`)"
  end

  def fmt(nil, error) do
    BotLog.emit("""
    ❌ unexpected error (no invocation given), error received:
    ```elixir
    #{inspect(error)}
    ```
    """)

    Logger.error(fn ->
      "unknown error: #{inspect(error)}"
    end)

    "❌ sorry, some unexpected error occurred :("
  end

  def fmt(msg, error) do
    """
    ❌ unexpected error caused by invocation: ```
    #{msg.content}
    ```
    error received:
    ```elixir
    #{inspect(error)}
    ```
    """
    |> String.slice(0..1999)
    |> BotLog.emit()

    Logger.error(fn ->
      "unknown error, original message: #{inspect(msg)}, error: #{inspect(error, pretty: true)}"
    end)

    "❌ sorry, some unexpected error occurred :("
  end
end
