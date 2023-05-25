defmodule Bolt.Cogs.Guide do
  @moduledoc false
  @behaviour Nosedrum.TextCommand

  alias Bolt.Constants
  alias Bolt.Paginator
  alias Nostrum.Struct.Embed

  @pages [
    %Embed{
      title: "guide - introduction",
      description: """
      bolt is a moderation bot intended for use on medium to large sized guilds.
      This command will guide you through using its abilities to help you moderate your guild.

      First off, keep in mind you can always invoke this command using `guide`, and if you want help for commands themselves, use `help <command>`.
      For subcommands (e.g. `infr list`), you can also view detailed help, e.g. `help infr list`.
      Commands documented here have their prefix omitted.

      To navigate through this guide, use the buttons below.
      """
    },
    %Embed{
      title: "guide - meta commands",
      description: """
      bolt provides a couple meta commands that can prove useful when moderating a server.
      These commands are generally available to everyone.

      • `guildinfo`
      shows you general information about the current guild.
      If you have a concrete guild ID you want to lookup, you can use `guildinfo <id>`.

      • `memberinfo`
      When run without commands, shows information about yourself.
      You can also pass this command a specific member you want to look up, for example `memberinfo @bolt`.
      The member ID can be useful when applying punishments to a member that you currently cannot see (e.g. in your staff channel), as you can pass it to commands that expect a member argument.

      • `roleinfo <role>`
      Looks up the given role. You can pass either the role ID, the role name, or mention the role.
      For example, to look up information about a role called 'Staff', use `roleinfo Staff`.
      The role ID can be useful when selecting actions that the automod should take, which will be explained later.

      • `roles [name]`
      Displays all roles on the guild. When given an argument, only displays roles matching the given name.

      • `stats`
      Displays general statistics about the bot.
      """
    },
    %Embed{
      title: "guide - mod log",
      description: """
      bolt comes with an extensive and configurable moderation log.
      You can configure it to output only select information on a per-channel basis.

      The command used to manage the mod log is `modlog`. It provides a bunch of subcommands for configuring the mod log as well as disabling it temporarily.
      It works based on events sent by the bot internally. A couple of these are events from Discord themselves - for example, a member joining - and others are events used by the bot.

      If you just want to go for a "set it and forget it" configuration, use `modlog set all <logchannel>`, where `logchannel` is the channel you want to log in (e.g. `modlog set all #modlog`). This will simply log all events captured by the bot in the given channel.

      Otherwise, if you want more fine-grained configuration, use `modlog set <event> <logchannel>`. Known events can be seen by using `modlog events`, and you can ask bolt to explain an event to you by using `modlog explain <event>`.

      It is recommended to at least enable the mod log for the following events:
      • `AUTOMOD`: automatic moderator actions the bot takes (when configured)
      • `BOT_UPDATE`: important bot updates
      • `CONFIG_UPDATE`: someone updated your configuration for bolt
      • `INFRACTION_CREATE`: an infraction was created
      • `INFRACTION_UPDATE`: an infraction was updated
      • `INFRACTION_EVENTS`: the bot did something based on an infraction
      • `MESSAGE_CLEAN`: a moderator ran the `clean` command, includes the deleted messages
      Infractions will be explained in detail on the next page.
      """
    },
    %Embed{
      title: "guide - infractions",
      description: """
      bolt ships an infraction system. In a nutshell, it's a database tracking everything that you've done on members through bolt.

      The following commands create new infractions: `note`, `warn`, `temprole`, `kick`, `tempban` and `ban`.
      You can list all infractions on your guild with `infr list`, and look up individual infractions using `infr detail <id>`. Finally, to show infractions for a member (or even users who left), use `infr user <member>`.
      To edit the reason for an infraction, use `infr reason <id> <new_reason>`. To update the expiration date of a timed infraction (for example, temporary bans), use `infr expiry <id> <new_expiry>`. The expiration date will be calculated relative to the creation time of the infraction.

      Note how I use `infr` here instead of the described `infraction`. Both commands work, `infr` is an alias.
      As usual, keep in mind that you can use `help infraction` or `help infr` to look up detailed documentation for this command.

      The next page will explain available moderation commands.
      """
    },
    %Embed{
      title: "guide - moderation commands",
      description: """
      As a moderation bot, bolt has many moderation utilities. This page describes those that you can execute yourself.

      The basic moderation commands are the following:
      • `note <user> <note>` applies a note on the given user
      • `warn <user> <reason>` warns the given user with the given reason
      • `temprole <user> <role> <duration> [reason]` will temporarily apply the given role to the given user
      • `kick <user> [reason]` kicks the given user
      • `tempban <user> <duration> [reason]` temporarily bans the given user
      • `ban <user> [reason]` permanently bans the given user
      • `clean <args>` to clean messages

      If you're confused by what to pass to some commands, just check `help <command>` as usual.
      All of these commands (except `clean`) will be logged with the event `INFRACTION_CREATE`, and `temprole` or `tempban` will also log with `INFRACTION_EVENTS` when they perform an action (such as unbanning someone).

      The next page will talk about automating role assignment.
      """
    },
    %Embed{
      title: "guide - self-assignable roles",
      description: """
      Many guilds want to have a bunch of roles that members can assign by themselves without moderator intervention.
      Self-assignable roles allow you to configure just that.

      At its core, moderators (with the permission to manage roles) can use the following:
      • `role allow <role>` to make a role self-assignable
      • `role deny <role>` to remove a role from the self-assignable roles
      Use `help role` if you want further information on these commands.
      These configuration commands will be logged under `CONFIG_UPDATE`.

      Users can then interact with the self-assignable roles using the following:
      • `lsar` to list all self-assignable roles
      • `assign` or `iam` to assign a self-assignable role
      • `remove` or `iamn` to remove a self-assignable role
      Users succeeding in assigning or removing a role will be logged under `AUTOMOD`.
      """
    },
    %Embed{
      title: "guide - combatting spam",
      description: """
      bolt can take some work off fighting off spam for you using the built-in *uncomplicated spam wall* (USW).
      USW works based on filters and punishment. Basically, it works like the following:
      If a user sends a message,
      - get all configured filters for the guild
      - apply all of those on the new message
      - if a filter triggers / "hits", punish the user with the configured punishment.

      To configure a punishment, use `usw punish`. For example, to apply the role "Muted" to someone triggering a filter for 5 minutes, use `usw punish temprole Muted 5m`.
      To set up filters, use `usw set <filter> <count> <interval>`. For example, `usw set BURST 5 10` would mean "allow 5 messages to pass through the `BURST` filter within 10 seconds.
      To unset configuration for a filter, use `usw unset <filter>`.
      Bolt will create infractions for hit filters depending on the punishment, which
      you can see via the `(automod)` word in the infraction reason.

      You can see the current configuration for USW on your guild using `usw status`.
      As always, use `help usw` if you need further help with this command.
      """
    },
    %Embed{
      title: "guide - gatekeeper",
      description: """
      bolt can automate assigning users roles or welcoming users when they join the server.
      bolt also includes the customizable `accept` command.

      The actions which should be triggered on either member join or `accept` invocation can be configured via the **gatekeeper** system. To use it, see:
      - `gk onjoin` for configuring member join actions
      - `gk onaccept` for configuring accept command actions
      - `gk actions` for viewing configured actions

      See the help pages for these commands for more information.
      """
    },
    %Embed{
      title: "guide - tags",
      description: """
      If you encounter often answering the same questions all over again or just want to provide a bunch of useful information some way, then the tags feature is for you.
      In a nutshell, you can create, read, and delete tags with this command.

      To create a tag, use `tag create <name> <content>`. For example, to create a tag named "duck pics" with questionable content, use `tag create "duck pics" What did you expect?`. Members can now use `tag duck pics` to read it.
      Note that you need to put quotes around the tag name for names spanning multiple words, or bolt will assume that all words after the first one are part of the tag's content.
      You can list all tags on the guild using `tag list`, and if you want to get rid of the tag, you can use `tag delete <name>`.

      Use `help tag` if you want more detailed information.
      """
    },
    %Embed{
      title: "guide - fin",
      description: """
      This sums up the guide for now.
      If you want to give feedback, have questions, want to suggest a feature, or simply want to be informed about updates, don't hesitate to join its server: https://discord.gg/5REguKf
      I hope that you enjoy using bolt and it provides use to your server.
      """
    }
  ]

  @impl true
  def usage, do: ["guide"]

  @impl true
  def description,
    do: """
    New to bolt? This command is a paginated overview showcasing how to use bolt on your server.
    """

  @impl true
  def predicates, do: []

  @impl true
  def command(msg, _args) do
    base_embed = %Embed{
      color: Constants.color_blue()
    }

    Paginator.paginate_over(msg, base_embed, @pages)
  end
end
