defmodule Bolt.Commander.Server do
  @moduledoc """
  The command server holds all commands internally an
  implements a simple GenServer. While currently rather dumb,
  it can later be expanded to support runtime modification of commands.
  """

  alias Bolt.Cogs
  alias Bolt.Commander.Checks
  alias Bolt.Commander.Parsers
  use GenServer

  @commands %{
    ## Built-in help with dummy commands,
    "syntax" => %{
      callback: &Cogs.Dummy.command/2,
      help: """
      Bolt uses various symbols and fancy names to describe how to use a command:

      **Argument syntax**
      If you want to pass multiple words as a single argument, surround it in quotes, for example `tempban "Some Spammer" 2d`.
      • `<arg>` is a required argument.
      • `[arg]` is an optional argument.
      • `arg...` means the argument will "consume the rest" - if your argument spans more than one word, you don't need to surround it with quotes.

      **Argument types**
      In argument specifications, the name preceding of `:` stands for the name of the argument, and the name following stands for the argument *type*. The following types are supported:
      • `member`: A guild member. You can specify this with the member ID, by mention, a User#Discrim combination, the username, or the nickname.
      • `role`: A guild role. You can specify this with the role ID, by mention, or with the role name.
      • `channel`: A guild channel. You can specify this with the channel ID, by mention, or with the channel name.
      • `duration`: A duration, usually for expiration dates. For example:
        `3d4h`: 3 days and 4 hours.
        `30s`: 30 seconds.
        `5w3d`: 5 weeks and 3 days.
        `w` for **w**eeks, `d` for **d**ays, `h` for **h**ours, `m` for **m**inutes, and `s` for **s**econds are supported.
      """,
      usage: ["help syntax"]
    },

    ## Meta Commands
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
    "memberinfo" => %{
      callback: &Cogs.MemberInfo.command/2,
      parser: &Parsers.join/1,
      help: """
      Without arguments, show information about yourself.
      When given a member, show information about the member instead of yourself.
      """,
      usage: [
        "memberinfo [user:member]"
      ],
      predicates: [&Checks.guild_only/1]
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
      usage: ["roles [name:str...]"],
      predicates: [&Checks.guild_only/1]
    },
    "stats" => %{
      callback: &Cogs.Stats.command/2,
      help: "Show statistics about the bot.",
      usage: ["stats"]
    },
    "lsar" => %{
      callback: &Cogs.Lsar.command/2,
      help: """
      Show all self-assignable roles on this guild.
      Self-assignable roles are roles that were configured to be assignable by any member on the guild.

      Related commands: `assign`, `remove`, `role allow`, `role deny`.

      **Examples**:
      ```rs
      // make the role 'Movie Nighter' self-assignable
      role allow movie nighter

      // list self-asignable roles, shows 'Movie Nighter'
      lsar
      ```
      """,
      usage: ["lsar"],
      predicates: [&Checks.guild_only/1]
    },
    "assign" => %{
      callback: &Cogs.Assign.command/2,
      parser: &Parsers.join/1,
      help: """
      Assign the given self-assignable role to yourself.
      To see which roles are self-assignable, use `lsar`.
      Aliased to `iam`.

      **Examples**:
      ```rs
      // assign the role 'Movie Nighter'
      assign movie nighter
      ```
      """,
      usage: ["assign <role:role...>"],
      predicates: [&Checks.guild_only/1]
    },
    "remove" => %{
      callback: &Cogs.Remove.command/2,
      parser: &Parsers.join/1,
      help: """
      Remove the given self-assignable role from yourself.
      To see which roles are self-assignable, use `lsar`.
      Aliased to `iamn`.

      **Examples**:
      ```rs
      // unassign the role 'Movie Nighter'
      remove movie nighter
      ```
      """,
      usage: ["remove <role:role...>"],
      predicates: [&Checks.guild_only/1]
    },

    ## Moderation Commands
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
    "note" => %{
      callback: &Cogs.Note.command/2,
      help: """
      Create a note for the given user.
      The note is stored in the infraction database, and can be retrieved later.
      Requires the `MANAGE_MESSAGES` permission.

      **Examples**:
      ```rs
      note @Dude#0001 has an odd affection to ducks
      ```
      """,
      usage: ["note <user:member> <note:str...>"],
      predicates: [
        &Checks.guild_only/1,
        &Checks.can_manage_messages?/1
      ]
    },
    "warn" => %{
      callback: &Cogs.Warn.command/2,
      help: """
      Warn the given user for the specified reason.
      The warning is stored in the infraction database, and can be retrieved later.
      Requires the `MANAGE_MESSAGES` permission.

      **Examples**:
      ```rs
      warn @Dude#0001 spamming duck images at #dog-pics
      ```
      """,
      usage: ["warn <user:member> <reason:str...>"],
      predicates: [&Checks.guild_only/1, &Checks.can_manage_messages?/1]
    },
    "temprole" => %{
      callback: &Cogs.Temprole.command/2,
      help: """
      Temporarily apply the given role to the given user.
      An infraction is stored in the infraction database, and can be retrieved later.
      Requires the `MANAGE_ROLES` permission.

      **Examples**:
      ```rs
      // apply the role "Shitposter" to Dude for 24 hours
      temprole @Dude#0001 Shitposter 24h

      // the same thing, but with a specified reason
      temprole @Dude#0001 Shitposter 24h spamming lol no generics near gophers
      ```
      """,
      usage: ["temprole <user:member> <role:role> <duration:duration> [reason:str...]"],
      predicates: [&Checks.guild_only/1, &Checks.can_manage_roles?/1]
    },
    "kick" => %{
      callback: &Cogs.Kick.command/2,
      help: """
      Kick the given member with an optional reason.
      An infraction is stored in the infraction database, and can be retrieved later.
      Requires the `KICK_MEMBERS` permission.

      **Examples**:
      ```rs
      // kick Dude without an explicit reason
      kick @Dude#0001

      // kick Dude with an explicit reason
      kick @Dude#0001 spamming cats when asked to post ducks
      ```
      """,
      usage: ["kick <user:member> [reason:str...]"],
      predicates: [&Checks.guild_only/1, &Checks.can_kick_members?/1]
    },
    "tempban" => %{
      callback: &Cogs.Tempban.command/2,
      help: """
      Temporarily ban the given user for the given duration with an optional reason.
      An infraction is stored in the infraction database, and can be retrieved later.
      Requires the `BAN_MEMBERS` permission.

      **Examples**:
      ```rs
      // tempban Dude for 2 days without a reason
      tempban @Dude#0001 2d

      // the same thing, but with a specified reason
      tempban @Dude#0001 2d posting cats instead of ducks
      ```
      """,
      usage: ["tempban <user:snowflake|member> <duration:duration> [reason:str...]"],
      predicates: [&Checks.guild_only/1, &Checks.can_ban_members?/1]
    },
    "ban" => %{
      callback: &Cogs.Ban.command/2,
      help: """
      Ban the given user with an optional reason.
      An infraction is stored in the infraction database, and can be retrieved later.
      Requires the `BAN_MEMBERS` permission.

      **Examples**:
      ```rs
      // ban Dude without a reason
      ban @Dude#0001

      // the same thing, but with a reason
      ban @Dude#0001 too many cat pictures
      ```
      """,
      usage: ["ban <user:snowflake|member> [reason:str]"],
      predicates: [&Checks.guild_only/1, &Checks.can_ban_members?/1]
    },
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
        "infraction user <user:snowflake|member>",
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
      Requires the `ADMINISTRATOR` permission.

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
      predicates: [&Checks.guild_only/1, &Checks.is_admin?/1]
    },
    "usw" => %{
      callback: &Cogs.USW.command/2,
      help: "Uncomplicated spam wall",
      usage: ["usw"],
      predicates: [&Checks.guild_only/1, &Checks.is_admin?/1]
    },
    "tag" => %{
      callback: &Cogs.Tag.command/2,
      help: """
      Tag manager. Create, read, update, or delete tags.
      Tags can be used for displaying commonly used information to your members on-demand.

      **Subcommands**:
      • `tag <name:str...>`: View the tag with the given name. Case-insensitive.
      • `tag create <name:str> <content:str...>`: Create a new tag with the given name and content.
      • `tag delete <name:str...>`: Delete the tag with the given name. Case-sensitive.

      **Examples**:
      ```rs
      // create the tag "music" with some fancy music
      tag create music https://www.youtube.com/watch?v=DLzxrzFCyOs

      // view the tag "music"
      tag music

      // delete the tag "music"
      tag delete music
      """,
      usage: [
        "tag <name:str...>",
        "tag create <name:str> <content:str...>",
        "tag delete <name:str...>"
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
