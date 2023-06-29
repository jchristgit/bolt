defmodule Bolt.Redact.Supervisor do
  @moduledoc "Supervises redaction managers and workers"

  alias Bolt.Redact.Ingestor
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Ingest messages into the pending list
      Bolt.Redact.IngestSupervisor,
      # Delete messages in the pending list as configured
      {DynamicSupervisor, name: Bolt.Redact.DeleteSupervisor},
      {Bolt.Redact.Starter, name: Bolt.Redact.Starter}
    ]

    options = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.init(children, options)
  end

  def configure_ingestor(maybe_ingestion_state, channel_id, [config | _] = configs) do
    ingestion_worker =
      Ingestor.child_spec(maybe_ingestion_state, channel_id, configs, [
        {:global, {Ingestor, channel_id}}
      ])

    start_result = DynamicSupervisor.start_child(Bolt.Redact.IngestSupervisor, ingestion_worker)

    case start_result do
      {:ok, _pid} = result ->
        result

      {:error, {:already_started, pid}} ->
        :ok = Ingestor.flush(pid)
        DynamicSupervisor.start_child(Bolt.Redact.IngestSupervisor, ingestion_worker)
    end
  end
end
