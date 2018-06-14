defmodule Bolt.Helpers do
  alias Nostrum.Struct.User
  use Timex

  @doc """
  Returns the Avatar URL for the given user.
  If the user does not have any avatar hash,
  the default avatar for the discriminator is
  returned instead.
  """
  @spec avatar_url(User.t()) :: String.t()
  def avatar_url(user) do
    case user.avatar do
      nil -> "https://cdn.discordapp.com/embed/avatars/#{rem(user.discriminator, 5)}.png"
      hash -> "https://cdn.discordapp.com/avatars/#{user.id}/#{hash}.png"
    end
  end

  @doc """
  Convert a boolean value to the
  "human" string equivalent.

  ## Examples

    iex> Helpers.bool_to_human(true)
    "yes"
    iex> Helpers.bool_to_human(false)
    "no"
  """
  @spec bool_to_human(boolean) :: String.t()
  def bool_to_human(value) do
    case value do
      true -> "yes"
      false -> "no"
    end
  end

  @doc """
  Converts a valid datetime to a
  human-readable string in the form
  "dd.mm.yy hh:mm (n [seconds/minutes/hours/days/weeks/months/years] ago)"
  """
  @spec datetime_to_human(Nostrum.Struct.Snowflake.t()) :: String.t()
  def datetime_to_human(datetime) do
    "#{Timex.format!(datetime, "%d.%m.%y %H:%M", :strftime)} (#{Timex.from_now(datetime)})"
  end
end
