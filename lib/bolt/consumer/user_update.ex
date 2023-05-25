defmodule Bolt.Consumer.UserUpdate do
  @moduledoc "Handles the `USER_UPDATE` event."

  alias Bolt.{Helpers, Humanizer, ModLog}
  alias Nostrum.Cache.MemberCache
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
      log_message = "#{Humanizer.human_user(old_user)} #{diff_description}"

      []
      |> MemberCache.fold_by_user(new_user.id, fn {guild_id, _member}, acc -> [guild_id | acc] end)
      |> Enum.each(
        &ModLog.emit(
          &1,
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
