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
end
