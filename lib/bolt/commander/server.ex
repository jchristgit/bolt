defmodule Bolt.Commander.Server do
  @moduledoc """
  The command server holds all commands internally an
  implements a simple GenServer. While currently rather dumb,
  it can later be expanded to support runtime modification of commands.
  """

  alias Bolt.Cogs
  alias Bolt.Commander.Checks
  use GenServer

  @commands %{
    ## Bot meta commands
    "help" => Cogs.Help,
    "guide" => Cogs.Guide,
    "stats" => Cogs.Stats,

    ## Meta Commands
    "guildinfo" => Cogs.GuildInfo,
    "memberinfo" => Cogs.MemberInfo,
    "roleinfo" => Cogs.RoleInfo,
    "roles" => Cogs.Roles,

    ## Self-assignable roles
    "lsar" => Cogs.Lsar,
    "assign" => Cogs.Assign,
    "remove" => Cogs.Remove,

    ## Moderation Commands
    "clean" => Cogs.Clean,
    "note" => Cogs.Note,
    "warn" => Cogs.Warn,
    "temprole" => Cogs.Temprole,
    "kick" => Cogs.Kick,
    "tempban" => Cogs.Tempban,
    "ban" => Cogs.Ban,
    "infraction" => %{
      callback: &Cogs.Infraction.command/2,
      help: """
      Operations on the infraction database.
      Requires the `MANAGE_MESSAGES` permission.

      **Subcommands**:
      • `detail <id:int>`: View the given infraction ID in detail.
      • `reason <id:int> <reason:str...>`: Update the reason for the given infraction ID.
      • `list [type:str]`: View all infractions, or only infractions with the given type
      • `user <user:snowflake|member>`: View all infractions for the given user,
      • `expiry <id:int> <new_expiry:duration>`: Update the expiry of the given infraction, relative to the creation date.

      **Examples**:
      ```rs
      // view infraction #538
      infr detail 538

      // set infraction #32's reason to "spamming"
      infr reason 32 spamming

      // view all infractions with the type "tempban"
      infr list tempban

      // view all of Dude's infractions
      infr user @Dude#0001

      // update the expiry of infraction 12 to be 24 hours after it was created
      infr expiry 12 24h
      ```
      """,
      usage: [
        "infraction detail <id:int>",
        "infraction reason <id:int> <reason:str...>",
        "infraction list [type:str]",
        "infraction user <user:snowflake|member...>",
        "infraction expiry <id:int> <new_expiry:duration>"
      ],
      predicates: [&Checks.guild_only/1, &Checks.can_manage_messages?/1]
    },
    "role" => %{
      callback: &Cogs.Role.command/2,
      help: """
      Manage self-assignable roles.
      Self-assignable roles are special roles that can be assigned my members through bot commands.
      Requires the `MANAGE_ROLES` permission.

      **Subcommands**:
      - `allow <role:role...>`: Allow self-assignment of the given role.
      - `deny <role:role...>`: Deny self-assignment of the given role.

      **Examples**:
      ```rs
      // allow self-assignment of the 'Movie Nighter' role
      role allow movie nighter

      // remove it from the self-assignable roles again
      role deny movie nighter
      ```
      """,
      usage: ["role allow <role:role...>", "role deny <role:role...>"],
      predicates: [&Checks.guild_only/1, &Checks.can_manage_roles?/1]
    },
    "modlog" => %{
      callback: &Cogs.ModLog.command/2,
      help: """
      Control the moderation log.
      Requires the `MANAGE_GUILD` permission.

      **Subcommands**:
      • `status`: show the current configuration
      • `set <event:str> <channel:textchannel>`: log the given event in the given channel
      • `unset <event:str>`: stop logging the given event
      • `events`: list known events
      • `explain <event:str>`: explain the given event
      • `mute`: mute the modlog temporarily (will reset if the bot restarts)
      • `unmute`: unmute the modlog

      If `all` is given in place of `event`, bolt will log all events to the given channel (when invoked with `set`) or no longer log anything (when invoked with `unset`).
      """,
      usage: [
        "modlog status",
        "modlog set <event:str> <channel:textchannel>",
        "modlog unset <event:str>",
        "modlog events",
        "modlog explain <event:str>",
        "modlog mute",
        "modlog unmute"
      ],
      predicates: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]
    },
    "usw" => %{
      callback: &Cogs.USW.command/2,
      help: """
      **Uncomplicated spam wall**
      Provides subcommands for managing the anti-spam subsystem *USW*.
      Requires the `MANAGE_GUILD` permission.

      **Subcommands**:
      • `usw status`: show the current configuration
      • `usw set <filter:str> <count:int> <interval:int>`: enable the given filter and set it to allow `count` objects in an interval of `interval` seconds
      • `usw unset <filter:str>`: disable the given filter
      • `usw punish <punishment...>`: apply the given punishment when the filter hits
      • `usw escalate [on|off]`: enable or disable automatic punishment escalation

      **Filters**:
      • `BURST`: Filters repeated messages in a short amount of time by a single user

      **Punishments**:
      • `temprole <role:role> <duration:duration>`: temporary apply the given role for `duration`

      **Examples**:
      ```rs
      // enable the `BURST` filter to allow max. 5 messages in 10 seconds
      usw set BURST 5 10
      ```
      """,
      usage: [
        "usw status",
        "usw set <filter:str> <count:int> <interval:int>",
        "usw unset <filter:str>",
        "usw punish <punishment...>",
        "usw escalate [on|off]"
      ],
      predicates: [&Checks.guild_only/1, &Checks.can_manage_guild?/1]
    },
    "tag" => %{
      callback: &Cogs.Tag.command/2,
      help: """
      Tag manager. Create, read, or delete tags.
      Tags can be used for displaying commonly used information to your members on-demand.

      **Subcommands**:
      • `tag <name:str...>`: View the tag with the given name. Case-insensitive.
      • `tag create <name:str> <content:str...>`: Create a new tag with the given name and content.
      • `tag delete <name:str...>`: Delete the tag with the given name. Case-sensitive.
      • `tag list`: List all tags on this guild.

      **Examples**:
      ```rs
      // create the tag "music" with some fancy music
      tag create music www.youtube.com/watch?v=DLzxrzFCyOs

      // view the tag "music"
      tag music

      // delete the tag "music"
      tag delete music
      ```
      """,
      usage: [
        "tag <name:str...>",
        "tag create <name:str> <content:str...>",
        "tag delete <name:str...>",
        "tag list"
      ],
      predicates: [&Checks.guild_only/1]
    },

    ## Bot Management commands
    "sudo" => %{
      callback: &Cogs.Sudo.command/2,
      help: """
      We trust you have received the usual lecture from the local System Administrator. It usually boils down to these three things:
      #1) Respect the privacy of others.
      #2) Think before you type.
      #3) With great power comes great responsibility.
      """,
      usage: ["sudo ?"],
      predicates: [&Checks.is_superuser?/1]
    }
  }

  @aliases %{
    "ginfo" => "guildinfo",
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
