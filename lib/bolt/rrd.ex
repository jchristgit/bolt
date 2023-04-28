defmodule Bolt.RRD do
  @moduledoc false

  require Logger

  @ds_name "messages"
  @messages_step_size "1h"
  @create_rra_cmdline [
    # Average value over the step size, stored for the past 14 days
    "RRA:AVERAGE:0.5:#{@messages_step_size}:14d",
    # Average value over 1 day, stored for the past 6 months
    "RRA:AVERAGE:0.5:1d:6M",
    # Average value over 1 week, stored for the past 5 years
    "RRA:AVERAGE:0.5:1w:#{52 * 5}w"
  ]

  use GenServer

  # Client API
  def create_guilds_directory do
    command("mkdir guilds")
  end

  def create_guild(guild_id) when is_integer(guild_id) do
    command("mkdir guilds/#{guild_id}")
  end

  def create_guild_channels(guild_id) when is_integer(guild_id) do
    command("mkdir guilds/#{guild_id}/channels")
  end

  def create_channel_messages(guild_id, channel_id)
      when is_integer(guild_id) and is_integer(channel_id) do
    command([
      "create",
      guild_messages_rrd(guild_id, channel_id),
      "--step",
      @messages_step_size,
      "--no-overwrite",
      "DS:#{@ds_name}:ABSOLUTE:7d:U:U" | @create_rra_cmdline
    ])
  end

  def count_channel_message(guild_id, channel_id, timeout \\ 10_000)
      when is_integer(guild_id) and is_integer(channel_id) do
    cmdline = "update #{guild_messages_rrd(guild_id, channel_id)} N:1"
    response = command(cmdline, timeout)

    case response do
      {:ok, _timings} = result ->
        result

      {:error, :timeout} = result ->
        result

      {:error, reason} = result ->
        if String.contains?(reason, "No such file or directory") do
          {:ok, _} = exists_ok(create_guilds_directory())
          {:ok, _} = exists_ok(create_guild(guild_id))
          {:ok, _} = exists_ok(create_guild_channels(guild_id))
          {:ok, _} = exists_ok(create_channel_messages(guild_id, channel_id))
          Logger.debug("Created messages RRD for guild #{guild_id}, channel #{channel_id}")
          # Don't recurse here.
          command(cmdline, timeout)
        else
          result
        end
    end
  end

  defp guild_messages_rrd(guild_id, channel_id)
       when is_integer(guild_id) and is_integer(channel_id) do
    "guilds/#{guild_id}/channels/#{channel_id}-messages.rrd"
  end

  defp exists_ok({:ok, _response} = result) do
    result
  end

  defp exists_ok({:error, response} = result) do
    if String.ends_with?(response, "File exists\n") do
      {:ok, "already exists"}
    else
      result
    end
  end

  defp quote_arg("-" <> _rest = arg), do: arg
  defp quote_arg(arg), do: "'#{arg}'"

  def command(content), do: command(content, 5_000)

  def command(content, timeout) when is_list(content) do
    quoted_command =
      content
      |> Stream.map(&quote_arg/1)
      |> Enum.join(" ")

    GenServer.call(__MODULE__, {:command, quoted_command, timeout - 1_000}, timeout)
  end

  def command(content, timeout) do
    GenServer.call(__MODULE__, {:command, content, timeout - 1_000}, timeout)
  end

  def enabled? do
    Application.get_env(:bolt, :rrd_directory) != nil
  end

  # GenServer API

  def start_link(_args) do
    directory = Application.get_env(:bolt, :rrd_directory)
    GenServer.start_link(__MODULE__, directory, name: __MODULE__)
  end

  def init(nil), do: :ignore

  def init(directory) when is_binary(directory) do
    {:ok, nil, {:continue, directory}}
  end

  def handle_continue(directory, nil) do
    executable = Application.get_env(:bolt, :rrd_executable) || "/usr/bin/rrdtool"

    port =
      Port.open({:spawn_executable, executable}, [
        :binary,
        :exit_status,
        args: ["-", directory]
      ])

    {:noreply, port}
  end

  def handle_call({:command, content, timeout}, _from, port) do
    Port.command(port, content <> "\n")

    receive do
      {^port, {:data, "OK " <> message}} ->
        {:reply, {:ok, message}, port}

      {^port, {:data, "ERROR: " <> message}} ->
        {:reply, {:error, message}, port}

      {^port, {:data, result}} ->
        {_, lines} = List.pop_at(String.split(result, "\n"), -1)
        {status, lines} = List.pop_at(lines, -1)

        case status do
          "OK " <> message ->
            {:reply, {:ok, message, lines}, port}

          "ERROR: " <> message ->
            {:reply, {:error, message}, port}
        end
    after
      timeout ->
        {:reply, {:error, :timeout}, port}
    end
  end

  def handle_info({port, {:data, "OK " <> _rest}}, port) do
    # we got a reply but the client is no longer waiting for it.
    # since the reply is an OK, we are OK with it.
    {:noreply, port}
  end

  def handle_info({_port, {:exit_status, status}}, state) do
    {:stop, {:rrd_exit, status}, state}
  end
end
