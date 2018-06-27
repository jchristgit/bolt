defmodule Bolt.USW do
  @moduledoc "USW - Uncomplicated Spam Wall"

  alias Bolt.Events.Handler
  alias Bolt.Helpers
  alias Bolt.ModLog
  alias Bolt.Repo
  alias Bolt.Schema.{USWFilterConfig, USWPunishmentConfig}
  alias Bolt.USW.Filters.{Burst}
  alias Nostrum.Api
  alias Nostrum.Struct.User
  import Ecto.Query, only: [from: 2]

  @spec filter_to_fn(USWFilterConfig) ::
          (Nostrum.Struct.Message.t(), non_neg_integer(), non_neg_integer() ->
             :action | :passthrough)
  defp filter_to_fn(%USWFilterConfig{filter: "BURST"}), do: &Burst.apply/3

  @spec config_to_fn(Nostrum.Struct.Message.t(), USWFilterConfig) ::
          (() -> :action | :passthrough)
  defp config_to_fn(msg, config) do
    fn ->
      func = filter_to_fn(config)
      func.(msg, config.count, config.interval)
    end
  end

  @spec apply(Nostrum.Struct.Message.t()) :: :ok
  def apply(msg) do
    query =
      from(
        config in USWFilterConfig,
        where: [guild_id: ^msg.guild_id],
        select: config
      )

    case Repo.all(query) do
      nil ->
        :ok

      configurations ->
        configurations
        |> Stream.map(&config_to_fn(msg, &1))
        |> Enum.find(:ok, &(&1.() == :action))
    end
  end

  @spec execute_config(USWPunishmentConfig, Nostrum.Struct.User.t(), String.t()) ::
          (() -> {:ok, Nostrum.Struct.Message.t()} | Nostrum.Api.error() | :noop)
  defp execute_config(
         %USWPunishmentConfig{
           guild_id: guild_id,
           punishment: "TEMPROLE",
           data: %{"role_id" => role_id},
           duration: expiry_seconds
         },
         user,
         description
       ) do
    with {:ok} <- Api.add_guild_member_role(guild_id, user.id, role_id),
         event_map <- %{
           timestamp:
             DateTime.utc_now()
             |> DateTime.to_unix()
             |> Kernel.+(expiry_seconds)
             |> DateTime.from_unix()
             |> elem(1),
           event: "REMOVE_ROLE",
           data: %{
             "guild_id" => guild_id,
             "user_id" => user.id,
             "role_id" => role_id
           }
         },
         {:ok, event} <- Handler.create(event_map) do
      ModLog.emit(
        guild_id,
        "AUTOMOD",
        "added temporary role `#{role_id}` to #{User.full_name(user)} (`#{user.id}`)" <>
          " for #{expiry_seconds}s: #{description}"
      )
    else
      {:error, %{status_code: status, message: %{"message" => reason}}} ->
        ModLog.emit(
          guild_id,
          "AUTOMOD",
          "attempted adding temporary role `#{role_id}` to #{User.full_name(user)} (`#{user.id}`)" <>
            " but got API error: #{reason} (status code #{status})"
        )

      {:error, changeset} ->
        ModLog.emit(
          guild_id,
          "AUTOMOD",
          "added temporary role `#{role_id}` to #{User.full_name(user)} (`#{user.id}`)" <>
            " but could not create an event to remove it after #{expiry_seconds}s:" <>
            " #{Helpers.format_changeset_errors(changeset) |> Enum.join(", ")}"
        )
    end
  end

  @spec punish(Nostrum.Struct.Guild.id(), Nostrum.Struct.User.t(), String.t()) :: no_return()
  def punish(guild_id, user, description) do
    case Repo.get(USWPunishmentConfig, guild_id) do
      nil ->
        :noop

      config ->
        execute_config(config, user, description)
    end
  end
end
