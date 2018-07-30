defmodule Bolt.Consumer.UserUpdate do
  @moduledoc "Handles the `USER_UPDATE` event."

  alias Bolt.ModLog
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.{Guild, User}

  @spec handle(User.t(), User.t()) :: ModLog.on_emit()
  def handle(old_user, new_user) do
    difference_list = [
      describe_diff(old_user.avatar, new_user.avatar, "avatar hash"),
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
      |> Stream.filter(&contains_user(new_user.id, &1))
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
  defp describe_diff(old_val, new_val, name)

  defp describe_diff(old_val, new_val, _key) when old_val == new_val, do: nil

  defp describe_diff(old_val, new_val, key) do
    "#{key} updated from #{old_val} to #{new_val}"
  end

  @spec contains_user(User.id(), Guild.t()) :: Enum.t()
  defp contains_user(user_id, guild) do
    user_id in Stream.map(guild.members, & &1.user.id)
  end
end
