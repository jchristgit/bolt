defmodule Bolt.Commander.Checks do
  @moduledoc "Implements various checks used by commands."

  alias Bolt.{BotLog, Helpers}
  alias Nostrum.Struct.{Message, User}
  use Bitwise

  @doc "Checks that the message author is in the superuser list."
  @spec is_superuser?(Message.t()) :: {:ok, Message.t()} | {:error, String.t()}
  def is_superuser?(msg) do
    if msg.author.id in Application.fetch_env!(:bolt, :superusers) do
      BotLog.emit(
        "🔓 #{User.full_name(msg.author)} (`#{msg.author.id}`) passed the root user check" <>
          " and is about to invoke `#{Helpers.clean_content(msg.content)}`" <>
          " in channel `#{msg.channel_id}`"
      )

      {:ok, msg}
    else
      BotLog.emit(
        "🔒#{User.full_name(msg.author)} (`#{msg.author.id}`) attempted using the root-only" <>
          " command `#{Helpers.clean_content(msg.content)}` in channel `#{msg.channel_id}`" <>
          if(
            msg.guild_id != nil,
            do: " on guild ID `#{msg.guild_id}`",
            else: ", which is a direct message channel"
          )
      )

      {
        :error,
        "🚫 #{User.full_name(msg.author)} is not in the sudoers file." <>
          " This incident will be reported."
      }
    end
  end
end
