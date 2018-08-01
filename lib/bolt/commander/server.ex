defmodule Bolt.Commander.Server do
  @moduledoc """
  The command server holds all commands internally an
  implements a simple GenServer. While currently rather dumb,
  it can later be expanded to support runtime modification of commands.
  """

  alias Bolt.Cogs
  use GenServer

  @commands %{
    ## Bot meta commands
    "help" => Cogs.Help,
    "guide" => Cogs.Guide,
    "stats" => Cogs.Stats,

    ## Meta Commands
    "guildinfo" => Cogs.GuildInfo,
    "inrole" => Cogs.InRole,
    "memberinfo" => Cogs.MemberInfo,
    "roleinfo" => Cogs.RoleInfo,
    "roles" => Cogs.Roles,

    ## Self-assignable roles
    "lsar" => Cogs.Lsar,
    "assign" => Cogs.Assign,
    "remove" => Cogs.Remove,

    ## Role configuration
    "role" => %{
      ## Add / remove self-assignable roles
      "allow" => Cogs.Role.Allow,
      "deny" => Cogs.Role.Deny,

      ## Roles for specific tasks
      "mute" => Cogs.Role.Mute
    },

    ## Moderation Commands
    "clean" => Cogs.Clean,
    "forcenick" => Cogs.ForceNick,
    "warn" => Cogs.Warn,
    "temprole" => Cogs.Temprole,
    "kick" => Cogs.Kick,
    "tempban" => Cogs.Tempban,
    "ban" => Cogs.Ban,

    ## Infraction database operations
    "note" => Cogs.Note,
    "infraction" => %{
      "detail" => Cogs.Infraction.Detail,
      "reason" => Cogs.Infraction.Reason,
      "list" => Cogs.Infraction.List,
      "user" => Cogs.Infraction.User,
      "expiry" => Cogs.Infraction.Expiry
    },

    ## Mod Log management
    "modlog" => %{
      "status" => Cogs.ModLog.Status,
      "set" => Cogs.ModLog.Set,
      "unset" => Cogs.ModLog.Unset,
      "events" => Cogs.ModLog.Events,
      "explain" => Cogs.ModLog.Explain,
      "mute" => Cogs.ModLog.Mute,
      "unmute" => Cogs.ModLog.Unmute
    },

    ## Spam wall management
    "usw" => %{
      "status" => Cogs.USW.Status,
      "set" => Cogs.USW.Set,
      "unset" => Cogs.USW.Unset,
      "punish" => Cogs.USW.Punish,
      "escalate" => Cogs.USW.Escalate
    },

    ## Tag database CR[U]D
    "tag" => %{
      "create" => Cogs.Tag.Create,
      "delete" => Cogs.Tag.Delete,
      "info" => Cogs.Tag.Info,
      "list" => Cogs.Tag.List,
      "raw" => Cogs.Tag.Raw,
      default: Cogs.Tag
    },

    ## Member join configuration management
    "keeper" => %{
      "onaccept" => Cogs.GateKeeper.OnAccept,
      "onjoin" => Cogs.GateKeeper.OnJoin
    },

    ## Rule verification
    "accept" => Cogs.Accept,

    ## Bot Management commands
    "sudo" => Cogs.Sudo,

    ## Easter eggs
    "ed" => Cogs.Ed
  }

  @aliases %{
    "gatekeeper" => "keeper",
    "ginfo" => "guildinfo",
    "gk" => "keeper",
    "guild" => "guildinfo",
    "iam" => "assign",
    "iamn" => "remove",
    "infr" => "infraction",
    "man" => "help",
    "minfo" => "memberinfo",
    "member" => "memberinfo",
    "rinfo" => "roleinfo",
    "role" => "roleinfo"
  }

  ## Client API

  @doc "Start the command registry."
  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  @doc "Return a map with all available commands."
  @spec all_commands :: map
  def all_commands do
    GenServer.call(__MODULE__, :all_commands)
  end

  @doc "Fetch the command module or submap for the given command name. Respects aliases."
  @spec lookup(String.t()) :: map | Module.t() | nil
  def lookup(command_name) do
    GenServer.call(__MODULE__, {:lookup, command_name})
  end

  ## Server Callbacks

  @impl true
  def init(:ok) do
    {:ok, {@commands, @aliases}}
  end

  @impl true
  def handle_call(:all_commands, _from, {commands, _} = state) do
    {:reply, commands, state}
  end

  @impl true
  def handle_call({:lookup, name}, _from, {commands, aliases}) do
    case Map.get(commands, name) do
      nil ->
        case Map.get(aliases, name) do
          nil ->
            {:reply, nil, {commands, aliases}}

          command_alias ->
            module_or_map = Map.get(commands, command_alias)
            {:reply, module_or_map, {commands, aliases}}
        end

      module_or_map ->
        {:reply, module_or_map, {commands, aliases}}
    end
  end
end
