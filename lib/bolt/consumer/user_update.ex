defmodule Bolt.Consumer.UserUpdate do
  @moduledoc "Handles the `USER_UPDATE` event."

  alias Bolt.{Helpers, ModLog}
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.User

  @spec handle(User.t(), User.t()) :: ModLog.on_emit()
  def handle(old_user, new_user) do
    difference_list = [
      describe_diff(old_user.discriminator, new_user.discriminator, "discriminator"),
      describe_diff(old_user.username, new_user.username, "username")
    ]

    diff_description =
      difference_list
      |> Stream.reject(&(&1 == nil))
      |> Enum.join(", ")

    unless diff_description == "" do
      log_message = "#{User.full_name(old_user)} (`#{old_user.id}`) #{diff_description}"

      GuildCache.all()
      |> Stream.filter(&Map.has_key?(&1.members, new_user.id))
      |> Enum.each(
        &ModLog.emit(
          &1.id,
          "USER_UPDATE",
          log_message
        )
      )
    end
  end

  @spec describe_diff(
          User.avatar() | User.discriminator() | User.username(),
          User.avatar() | User.discriminator() | User.username(),
          String.t()
        ) :: String.t() | nil
  defp describe_diff(old_val, new_val, _key) when old_val == new_val, do: nil

  defp describe_diff(old_val, new_val, key),
    do:
      "#{key} updated from #{Helpers.clean_content(old_val)} to #{Helpers.clean_content(new_val)}"
end
