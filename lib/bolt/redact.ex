defmodule Bolt.Redact do
  @moduledoc """
  High-level functions for dealing with bolt's auto-redact feature.
  """

  alias Bolt.Redact
  alias Bolt.Repo
  alias Bolt.Schema.RedactChannelIngestionState, as: IngestionState
  alias Bolt.Schema.RedactConfig
  alias Bolt.Schema.RedactPendingMessage, as: PendingMessage
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Struct.Guild
  alias Nostrum.Struct.User
  import Ecto.Query, only: [from: 2]

  @typedoc "Per-guild redaction status for a single user."
  @type guild_redaction_status :: %{
          guild_id: Guild.id()
        }

  def configure(guild_id, user_id, age_in_seconds, excluded_channels) do
    patch = %{
      guild_id: guild_id,
      author_id: user_id,
      age_in_seconds: age_in_seconds,
      enabled: true,
      excluded_channels: excluded_channels
    }

    insertion_result =
      %RedactConfig{}
      |> RedactConfig.changeset(patch)
      |> Repo.insert(
        on_conflict: {:replace, [:age_in_seconds, :excluded_channels, :enabled]},
        conflict_target: [:guild_id, :author_id]
      )

    case insertion_result do
      {:ok, config} ->
        start_results = configure_workers(config)

        if Enum.all?(start_results, &match?({:ok, _pid}, &1)) do
          {:ok, config}
        else
          {:error, "not all workers started"}
        end

      other ->
        other
    end
  end

  @doc "Disable redaction for the given guild and user"
  def unconfigure(guild_id, user_id) do
    query =
      from config in RedactConfig,
        where: config.guild_id == ^guild_id and config.author_id == ^user_id

    {deleted, _} = Repo.delete_all(query)
    deleted
  end

  @spec info(Guild.id(), User.id()) :: guild_redaction_status | nil
  def info(guild_id, user_id) do
    guild = GuildCache.get!(guild_id)

    config_query =
      from config in RedactConfig,
        where: config.guild_id == ^guild_id and config.author_id == ^user_id

    with config when config != nil <- Repo.one(config_query),
         position_query =
           from(is in IngestionState,
             where: is.channel_id in ^Map.keys(guild.channels)
           ),
         worker_positions <- Repo.all(position_query),
         messages_query <-
           from(pending in PendingMessage, where: pending.config_id == ^config.id),
         pending_messages <- Repo.aggregate(messages_query, :count) do
      %{
        config: config,
        worker_positions: worker_positions,
        pending_messages: pending_messages
      }
    else
      nil -> nil
    end
  end

  def configure_workers(config) do
    channels = relevant_channels(config.guild_id, [])

    configs_query =
      from rc in RedactConfig,
        where: rc.guild_id == ^config.guild_id

    configs_query
    |> Repo.all()
    |> configure_guild_workers(channels)
  end

  @doc """
  Return channel IDs for channels relevant to the worker processes.
  """
  def relevant_channels(guild_id, excluded_channels) do
    guild_id
    |> GuildCache.get!()
    |> Map.fetch!(:channels)
    |> Stream.filter(fn {_id, channel} -> channel.type in [0, 11, 12, 15] end)
    |> Stream.map(fn {id, _channel} -> id end)
    |> Enum.reject(&(&1 in excluded_channels))
  end

  @doc """
  Start workers for the given configs.

  All given configs must be for a single guild.
  """
  def configure_guild_workers(configs, channel_ids) do
    Enum.map(channel_ids, fn channel ->
      configure_channel_workers(Enum.reject(configs, &(channel in &1.excluded_channels)), channel)
    end)
  end

  defp configure_channel_workers(configs, channel_id) do
    maybe_ingestion_state = Repo.get(IngestionState, channel_id)

    case maybe_ingestion_state do
      %{enabled: false} ->
        {:ok, :disabled}

      state ->
        {:ok, _} = Redact.Supervisor.configure_ingestor(state, channel_id, configs)
    end
  end
end
