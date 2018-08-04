defmodule Bolt.Cogs.Accept do
  @moduledoc false
  @behaviour Bolt.Command

  alias Bolt.Commander.Checks
  alias Bolt.{ModLog, Repo}
  alias Bolt.Schema.AcceptAction
  alias Nostrum.Api
  alias Nostrum.Struct.User
  import Ecto.Query, only: [from: 2]

  @impl true
  def usage, do: ["accept"]

  @impl true
  def description,
    do:
      "Verifies that you have read and accept the guild's rules and other information you have been asked to read."

  @impl true
  def predicates, do: [&Checks.guild_only/1]

  @impl true
  def command(msg, _args) do
    query = from(action in AcceptAction, where: action.guild_id == ^msg.guild_id)

    query
    |> Repo.all()
    |> Enum.each(&apply_action(&1, msg))
  end

  @spec apply_action(AcceptAction, Message.t()) :: :ok | ModLog.on_emit()
  defp apply_action(action, message)

  defp apply_action(
         %AcceptAction{action: "add_role", data: %{"role_id" => role_id}},
         msg
       ) do
    case Api.add_guild_member_role(msg.guild_id, msg.author.id, role_id) do
      {:ok} ->
        :ok

      {:error, %{status_code: status, message: %{"message" => reason}}} ->
        ModLog.emit(
          msg.guild_id,
          "ERROR",
          "attempted adding role `#{role_id}` " <>
            "to user #{User.full_name(msg.author)} (`#{msg.author.id}`) " <>
            "by invocation of `.accept`, but got an API error: #{reason} (status code #{status})"
        )
    end
  end

  defp apply_action(
         %AcceptAction{action: "remove_role", data: %{"role_id" => role_id}},
         msg
       ) do
    case Api.remove_guild_member_role(msg.guild_id, msg.author.id, role_id) do
      {:ok} ->
        :ok

      {:error, %{status_code: status, message: %{"message" => reason}}} ->
        ModLog.emit(
          msg.guild_id,
          "ERROR",
          "attempted removing role `#{role_id}` " <>
            "from user #{User.full_name(msg.author)} (`#{msg.author.id}`) " <>
            "by invocation of `.accept`, but got an API error: #{reason} (status code #{status})"
        )
    end
  end

  defp apply_action(%AcceptAction{action: "delete_invocation"}, msg) do
    case Api.delete_message(msg) do
      {:ok} ->
        :ok

      {:error, %{status_code: status, message: %{"message" => reason}}} ->
        ModLog.emit(
          msg.guild_id,
          "ERROR",
          "attempted deleting message " <>
            "https://discordapp.com/channels/#{msg.guild_id}/#{msg.channel_id}/#{msg.id}" <>
            "by invocation of `.accept`, but got an API error: #{reason} (status code #{status})"
        )
    end
  end
end
