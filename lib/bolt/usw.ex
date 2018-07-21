defmodule Bolt.USW do
  @moduledoc "USW - Uncomplicated Spam Wall"

  alias Bolt.ErrorFormatters
  alias Bolt.Events.Handler
  alias Bolt.{ModLog, Repo}
  alias Bolt.Schema.{USWFilterConfig, USWPunishmentConfig}
  alias Bolt.USW.{Deduplicator, Escalator}
  alias Bolt.USW.Filters.{Burst, Duplicates}
  alias Ecto.Changeset
  alias Nostrum.Api
  alias Nostrum.Cache.Me
  alias Nostrum.Struct.User
  import Ecto.Query, only: [from: 2]
  require Logger

  @spec filter_to_fn(USWFilterConfig) ::
          (Nostrum.Struct.Message.t(), non_neg_integer(), non_neg_integer() ->
             :action | :passthrough)
  defp filter_to_fn(%USWFilterConfig{filter: "BURST"}), do: &Burst.apply/3

  defp filter_to_fn(%USWFilterConfig{filter: "DUPLICATES"}), do: &Duplicates.apply/3

  @spec config_to_fn(Nostrum.Struct.Message.t(), USWFilterConfig) ::
          (() -> :action | :passthrough)
  defp config_to_fn(msg, config) do
    fn ->
      func = filter_to_fn(config)
      func.(msg, config.count, config.interval)
    end
  end

  @spec apply(Nostrum.Struct.Message.t()) :: :noop | :ok
  def apply(msg) do
    query =
      from(
        config in USWFilterConfig,
        where: [guild_id: ^msg.guild_id],
        select: config
      )

    case Repo.all(query) do
      [] ->
        :noop

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
           escalate: escalator_enabled,
           punishment: "TEMPROLE",
           data: %{"role_id" => role_id},
           duration: expiry_seconds
         },
         user,
         description
       ) do
    with false <- Deduplicator.contains?(user.id),
         {:ok} <- Api.add_guild_member_role(guild_id, user.id, role_id) do
      escalator_level = Escalator.level_for(user.id)

      expiry_seconds =
        if escalator_enabled do
          expiry_seconds + expiry_seconds * escalator_level
        else
          expiry_seconds
        end

      Deduplicator.add(user.id, expiry_seconds * 1000)

      level_string =
        if escalator_enabled do
          level_description =
            if(escalator_level == 0, do: "", else: " - escalation level #{escalator_level}")

          Escalator.bump(user.id, expiry_seconds * 1000 * 2)
          level_description
        else
          ""
        end

      infraction_map = %{
        type: "temprole",
        guild_id: guild_id,
        user_id: user.id,
        actor_id: Me.get().id,
        reason: "(automod) #{description}" <> level_string,
        expires_at:
          DateTime.utc_now()
          |> DateTime.to_unix()
          |> Kernel.+(expiry_seconds)
          |> DateTime.from_unix()
          |> elem(1),
        data: %{"role_id" => role_id}
      }

      {:ok, _event} = Handler.create(infraction_map)

      ModLog.emit(
        guild_id,
        "AUTOMOD",
        "added temporary role `#{role_id}` to #{User.full_name(user)} (`#{user.id}`)" <>
          " for #{expiry_seconds}s: #{description}" <> level_string
      )
    else
      # Deduplicator is active
      true ->
        Logger.debug("Deduplicator is active. Not applying temporary role.")

      {:error, %{status_code: status, message: %{"message" => reason}}} ->
        ModLog.emit(
          guild_id,
          "AUTOMOD",
          "attempted adding temporary role `#{role_id}` to #{User.full_name(user)} (`#{user.id}`)" <>
            " but got API error: #{reason} (status code #{status})"
        )

      {:error, %Changeset{} = _changeset} = error ->
        ModLog.emit(
          guild_id,
          "AUTOMOD",
          "added temporary role `#{role_id}` to #{User.full_name(user)} (`#{user.id}`)" <>
            " but could not create an event to remove it after #{expiry_seconds}s:" <>
            ErrorFormatters.fmt(nil, error)
        )

      error ->
        ModLog.emit(
          guild_id,
          "AUTOMOD",
          "added temporary role `#{role_id}` to #{User.full_name(user)} (`#{user.id}`) " <>
            "but got an unexpected error: #{ErrorFormatters.fmt(nil, error)}"
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
