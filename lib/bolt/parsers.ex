defmodule Bolt.Parsers do
  @moduledoc """
  Various helpers to parse inputs that are
  not related to the command handler.
  """

  @single_digit_numbers Enum.map(0..9, &Integer.to_string/1)

  alias Bolt.Helpers

  @spec seconds(String.t()) :: {:ok, integer} | {:error, String.t()}
  defp seconds(duration) when byte_size(duration) < 2 do
    {:error, "must specify at least the unit and time, e.g. `3d`, `4h`"}
  end

  defp seconds(duration) do
    {amount, unit} = String.split_at(duration, -1)
    # The amount being an integer is validated below.
    {value, _remainder} = Integer.parse(amount)

    case unit do
      "w" -> {:ok, value * 604_800}
      "d" -> {:ok, value * 86_400}
      "h" -> {:ok, value * 3_600}
      "m" -> {:ok, value * 60}
      "s" -> {:ok, value}
      _ -> {:error, "invalid unit: #{unit}"}
    end
  end

  @doc """
  Parse a duration string, e.g. `3h30m`, to seconds.
  The following tokens are supported:

    - `s` for seconds
    - `m` for minutes
    - `h` for hours
    - `d` for days
    - `w` for weeks

  Additionally, `now` is accepted as `0s`.

  ## Arguments

    - `text` - the string to parse.

  ## Return value

    - `{:ok, seconds}` is returned if the string could be parsed correctly.
    - `{:error, reason}` is returned if there was a parsing error due to invalid
      time unit or otherwise bad tokens.

  ## Examples

    iex> import Bolt.Parsers, only: [duration_string_to_seconds: 1]
    iex> duration_string_to_seconds("now")
    {:ok, 0}
    iex> duration_string_to_seconds("")
    {:error, "cannot parse a duration from an empty string"}
    iex> duration_string_to_seconds("1")
    {:error, "must specify at least the unit and time, e.g. `3d`, `4h`"}
    iex> duration_string_to_seconds("1m30s")
    {:ok, 90}
  """
  @spec duration_string_to_seconds(String.t()) :: {:ok, Calendar.second()} | {:error, String.t()}
  def duration_string_to_seconds(text)

  def duration_string_to_seconds("now"), do: {:ok, 0}

  def duration_string_to_seconds(text) do
    if String.trim(text) == "" do
      {:error, "cannot parse a duration from an empty string"}
    else
      parsed_seconds =
        text
        |> Helpers.clean_content()
        |> String.codepoints()
        # Thanks to https://github.com/jos-b
        # for coming up with this smart solution.
        |> Enum.reduce("", fn char, acc ->
          if char in @single_digit_numbers do
            acc <> char
          else
            acc <> char <> " "
          end
        end)
        |> String.split()
        |> Enum.map(&seconds/1)

      case Enum.find(parsed_seconds, &match?({:error, _}, &1)) do
        {:error, _reason} = res ->
          res

        nil ->
          total_seconds =
            parsed_seconds
            |> Stream.map(fn {:ok, seconds} -> seconds end)
            |> Enum.sum()

          {:ok, total_seconds}
      end
    end
  end

  @doc """
  Parse a 'human' datetime that lies in the future.

  While `duration_string_to_seconds/1` returns the total amount of seconds specified
  in a duration string, this function adds those seconds on top of the given
  `starting_timestamp`.

  ## Arguments

    - `text` - the string to parse.
    - `starting_timestamp` - the point in time to which the parsed seconds should be
      added.

  ## Return value

    - `{:ok, datetime}` is returned if parsing was successful,
    - `{:error, reason}` otherwise.
  """
  @spec human_future_date(String.t()) :: {:ok, DateTime.t()} | {:error, String.t()}
  def human_future_date(text, starting_timestamp \\ DateTime.utc_now()) do
    case duration_string_to_seconds(text) do
      {:ok, total_seconds} ->
        starting_timestamp
        |> DateTime.to_unix()
        |> Kernel.+(total_seconds)
        |> DateTime.from_unix()

      {:error, _reason} = error ->
        error
    end
  end
end
