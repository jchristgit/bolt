defmodule Bolt.USW do
  @moduledoc "USW - Uncomplicated Spam Wall"

  alias Bolt.ErrorFormatters
  alias Bolt.Events.Handler
  alias Bolt.{ModLog, Repo}
  alias Bolt.Schema.{USWPunishmentConfig, USWRuleConfig}
  alias Bolt.USW.{Deduplicator, Escalator, Filters}
  alias Ecto.Changeset
  alias Nostrum.Api
  alias Nostrum.Cache.{GuildCache, Me}
  alias Nostrum.Struct.{Message, Snowflake, User}
  import Ecto.Query, only: [from: 2]
  require Logger

  @filter_name_to_function %{
    "BURST" => &Filters.Burst.apply/4,
    "DUPLICATES" => &Filters.Duplicates.apply/4,
    "LINKS" => &Filters.Links.apply/4,
    "MENTIONS" => &Filters.Mentions.apply/4,
    "NEWLINES" => &Filters.Newlines.apply/4
  }

  @spec config_to_fn(Message.t(), USWRuleConfig) :: (() -> :action | :passthrough)
  defp config_to_fn(msg, config) do
    fn ->
      func = Map.fetch!(@filter_name_to_function, config.rule)

      snowflake_interval_seconds_ago =
        DateTime.utc_now()
        |> DateTime.to_unix()
        |> Kernel.-(config.interval)
        |> DateTime.from_unix!()
        |> Snowflake.from_datetime!()

      func.(msg, config.count, config.interval, snowflake_interval_seconds_ago)
    end
  end

  @spec apply(Message.t()) :: :noop | :ok | nil
  def apply(msg) do
    query =
      from(
        config in USWRuleConfig,
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

  @spec execute_config(USWPunishmentConfig, User.t(), String.t()) ::
          (() -> {:ok, Message.t()} | Api.error() | :noop)
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
          |> DateTime.from_unix!(),
        data: %{"role_id" => role_id}
      }

      {:ok, _event} = Handler.create(infraction_map)

      ModLog.emit(
        guild_id,
        "AUTOMOD",
        "added temporary role `#{role_id}` to #{User.full_name(user)} (`#{user.id}`)" <>
          " for #{expiry_seconds}s: #{description}" <> level_string
      )

      dm_user(guild_id, user)
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

  @spec punish(Guild.id(), User.t(), String.t()) :: no_return()
  def punish(guild_id, user, description) do
    case Repo.get(USWPunishmentConfig, guild_id) do
      nil ->
        :noop

      config ->
        execute_config(config, user, description)
    end
  end

  @spec dm_user(Guild.id(), User.t()) :: :noop | {:ok, Message.t()} | Api.Error
  defp dm_user(guild_id, user) do
    case Api.create_dm(user.id) do
      {:ok, dm} ->
        guild_desc =
          case GuildCache.get(guild_id) do
            {:ok, guild} ->
              guild.name

            _error ->
              guild_id
          end

        Api.create_message(
          dm.id,
          "you have been muted on `#{guild_desc}` for triggering " <>
            "a spam filter. contact a staff member for further information"
        )

      _error ->
        :noop
    end
  end
end
