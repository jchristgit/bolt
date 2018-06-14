defmodule Bolt.Commander.Server do
  alias Bolt.Cogs
  alias Bolt.Commander.Checks
  alias Bolt.Commander.Parsers
  use GenServer

  @commands %{
    "echo" => %{
      callback: &Cogs.Echo.command/2,
      parser: &Parsers.passthrough/1,
      help: "Echo the given command."
    },
    "guildinfo" => %{
      callback: &Cogs.GuildInfo.command/2,
      parser: &Parsers.passthrough/1,
      help: "Show information about the current Guild.",
      predicates: [&Checks.guild_only/1]
    },
    "memberinfo" => %{
      callback: &Cogs.MemberInfo.command/2,
      parser: &Parsers.passthrough/1,
      help: "Show information about the mentioned member, or yourself.",
      predicates: [&Checks.guild_only/1]
    },
    "roleinfo" => %{
      callback: &Cogs.RoleInfo.command/2,
      parser: &Parsers.passthrough/1,
      help: "Show information about the given role.",
      predicates: [&Checks.guild_only/1]
    },
    "roles" => %{
      callback: &Cogs.Roles.command/2,
      parser: &Parsers.passthrough/1,
      help: "Show all roles on the guild the command is invoked on.",
      predicates: [&Checks.guild_only/1]
    }
  }

  @aliases %{
    "ginfo" => "guildinfo",
    "guild" => "guildinfo",
    "minfo" => "memberinfo",
    "member" => "memberinfo",
    "rinfo" => "roleinfo",
    "role" => "roleinfo"
  }

  ## Client API

  @doc "Start the command registry."
  def start_link(options) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  @doc "Fetch the command map for the given command name. Respects aliases."
  @spec lookup(String.t()) :: map | nil
  def lookup(command_name) do
    GenServer.call(__MODULE__, {:lookup, command_name})
  end

  ## Server Callbacks

  @impl true
  def init(:ok) do
    {:ok, {@commands, @aliases}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, {commands, aliases}) do
    case Map.get(commands, name) do
      nil ->
        case Map.get(aliases, name) do
          nil ->
            {:reply, nil, {commands, aliases}}

          command_alias ->
            command_map = Map.get(commands, command_alias)
            {:reply, command_map, {commands, aliases}}
        end

      command_map ->
        {:reply, command_map, {commands, aliases}}
    end
  end
end
