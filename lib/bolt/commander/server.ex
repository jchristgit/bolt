defmodule Bolt.Commander.Server do
  alias Bolt.Cogs
  alias Bolt.Commander.Checks
  alias Bolt.Commander.Parsers
  use GenServer

  @commands %{
    "pingback" => %{
      callback: &Cogs.Pingback.command/2,
      parser: &Parsers.join/1,
      help: "pingback after the given `seconds`",
      usage: ["pingback <seconds:int>"]
    },
    "clean" => %{
      callback: &Cogs.Clean.command/2,
      parser: &Cogs.Clean.parse/1,
      help: """
      Cleanup messages. The execution of this command can be customized with the following options:
      `--bots`: Only clean messages authored by bots
      `--no-bots`: Do not clean any messages authored by bots
      `--limit <amount:int>`: Specify the limit of messages to delete
      `--channel <channel:textchannel>`: The channel to delete messages in
      `--user <user:snowflake|user>`: Only delete messages by this user, can be specified multiple times
      `--content <content:str>`: Only delete messages containing `content`

      **Examples**:
      ```rs
      // delete 30 messages in the current channel (default)
      clean

      // delete 60 messages in the current channel
      clean 60

      // delete up to 10 messages by 
      // bots in the current channel
      clean --bots --limit 10  

      // delete up to 30 messages sent 
      // by 197177484792299522 in the #fsharp channel
      clean --user 197177484792299522 --channel #fsharp

      // delete up to 50 messages containing 
      // "lol no generics" in the #golang channel
      clean --content "lol no generics" --channel #golang --limit 50
      ```
      """,
      usage: [
        "clean [amount:int=30]",
        "clean <options...>"
      ],
      predicates: [
        &Checks.guild_only/1,
        &Checks.can_manage_messages?/1
      ]
    },
    "guildinfo" => %{
      callback: &Cogs.GuildInfo.command/2,
      help:
        "Show information about the current Guild, or a given guild ID. Aliased to `ginfo` and `guild`.",
      usage: ["guildinfo [guild:snowflake]"],
      predicates: [&Checks.guild_only/1]
    },
    "help" => %{
      callback: &Cogs.Help.command/2,
      parser: &Parsers.join/1,
      help:
        "Show information about the given command, or, with no arguments given, list all commands.",
      usage: ["help [command:str]"]
    },
    "infraction" => %{
      callback: &Cogs.Infraction.command/2,
      help: """
      Various operations on the infraction database.
      Aliased to `infr`.
      """,
      usage: ["infraction detail"]
    },
    "memberinfo" => %{
      callback: &Cogs.MemberInfo.command/2,
      parser: &Parsers.join/1,
      help: """
      Without arguments, show information about yourself.
      When given an argument, attempt to convert the argument to a member - either per ID, mention, username#discrim, username, or nickname.
      """,
      usage: [
        "memberinfo",
        "memberinfo <member:user>"
      ],
      predicates: [&Checks.guild_only/1]
    },
    "note" => %{
      callback: &Cogs.Note.command/2,
      help: "Create a note for the given user. The note is stored in the infraction database.",
      usage: ["note <member:user> <note:str>"],
      predicates: [
        &Checks.guild_only/1,
        &Checks.can_manage_messages?/1
      ]
    },
    "roleinfo" => %{
      callback: &Cogs.RoleInfo.command/2,
      parser: &Parsers.join/1,
      help: """
      Show information about the given role.
      The role can be given as either a direct role ID, a role mention, or a role name (case-insensitive).
      """,
      usage: ["roleinfo <role:role>"],
      predicates: [&Checks.guild_only/1]
    },
    "roles" => %{
      callback: &Cogs.Roles.command/2,
      parser: &Parsers.join/1,
      help: """
      Show all roles on the guild the command is invoked on.
      When given a second argument, only roles which name contain the given `name` are returned (case-insensitive).
      """,
      usage: ["roles [name:str]"],
      predicates: [&Checks.guild_only/1]
    },
    "temprole" => %{
      callback: &Cogs.Temprole.command/2,
      help: "Temporarily apply the given role to the given user.",
      usage: ["temprole <user:member> <role:role> <duration:duration> [reason:str]"],
      predicates: [&Checks.guild_only/1, &Checks.can_manage_roles?/1]
    },
    "warn" => %{
      callback: &Cogs.Warn.command/2,
      help: "Warn the given user for the specified reason.",
      usage: ["warn <user:member> <reason:str>"],
      predicates: [&Checks.guild_only/1, &Checks.can_manage_messages?/1]
    }
  }

  @aliases %{
    "ginfo" => "guildinfo",
    "guild" => "guildinfo",
    "infr" => "infraction",
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

  @doc "Return a map with all available commands."
  @spec all_commands() :: map
  def all_commands() do
    GenServer.call(__MODULE__, :all_commands)
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
            command_map = Map.get(commands, command_alias)
            {:reply, command_map, {commands, aliases}}
        end

      command_map ->
        {:reply, command_map, {commands, aliases}}
    end
  end
end
