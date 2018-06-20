defmodule Bolt.Parsers do
  @moduledoc """
  Various helpers to parse inputs that are
  not related to the command handler.
  """

  alias Bolt.Helpers

  @spec parse_pos_integer(String.t()) :: {:ok, integer} | {:error, String.t()}
  defp parse_pos_integer(number) do
    case Integer.parse(number) do
      {value, _remainder} ->
        cond do
          value < 0 -> {:error, "number must not be negative (parsed #{value} from #{number})"}
          value == 0 -> {:error, "number must not be `0` (parsed from #{number})"}
          value > 0 -> {:ok, value}
        end

      :error ->
        {:error, "#{number} is not a valid number"}
    end
  end

  @spec seconds(String.t()) :: {:ok, integer} | {:error, String.t()}
  defp seconds(maybe_duration) do
    with string_length when string_length >= 2 <- String.length(maybe_duration),
         {amount, unit} <- String.split_at(maybe_duration, -1),
         {:ok, value} <- parse_pos_integer(amount) do
      case unit do
        "w" -> {:ok, value * 604_800}
        "d" -> {:ok, value * 86_400}
        "h" -> {:ok, value * 3_600}
        "m" -> {:ok, value * 60}
        "s" -> {:ok, value}
        _ -> {:error, "invalid unit: #{unit}"}
      end
    else
      number when is_integer(number) and number < 2 ->
        {:error, "must specify at least the unit and time, e.g. `3d`, `4h`"}

      {:error, _reason} = error ->
        error
    end
  end

  @doc "Parse a 'human' datetime that lies in the future."
  @spec human_future_date(String.t()) :: {:ok, DateTime.t()} | {:error, String.t()}
  def human_future_date(text) do
    parsed_seconds =
      text
      |> Helpers.clean_content()
      |> String.codepoints()
      # Thanks to https://github.com/JoeBanks13
      # for coming up with this smart solution.
      |> Enum.reduce("", fn char, acc ->
        case Integer.parse(char) do
          :error -> acc <> char <> " "
          _value -> acc <> char
        end
      end)
      |> String.split()
      |> Enum.map(&seconds/1)

    case Enum.find(parsed_seconds, &match?({:error, _}, &1)) do
      {:error, reason} ->
        {:error, reason}

      nil ->
        parsed_seconds = Enum.map(parsed_seconds, fn {:ok, seconds} -> seconds end)

        {:ok, result_timestamp} =
          DateTime.utc_now()
          |> DateTime.to_unix()
          |> (fn now -> now + Enum.sum(parsed_seconds) end).()
          |> DateTime.from_unix()

        {:ok, result_timestamp}
    end
  end
end
