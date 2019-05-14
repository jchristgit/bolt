# Moderation
This page showcases the general moderational tools available at your disposal. Infraction management and automod configuration documentation is available on their own pages.


## Commands
### `.warn <user:member> <reason:str...>`
Warns the given user for the specified reason. The warning is stored in the infraction database, and can be retrieved later.
Requires the `MANAGE_MESSAGES` permission.
```js
// Warn the mentioned member for the given reason.
.warn @Guy spamming #general with nonsense

// Warn a member by their ID instead.
.warn 252908391075151874 repeated spamming in voice chat
```

### `.forcenick <user:member> <duration:duration> <nick:str...>`
Temporarily apply the given nickname to the given user. If the member attempts changing their nickname while the infraction is active, bolt will reset it to the configured nickname and log it under `INFRACTION_EVENTS`.
Requires the `MANAGE_NICKNAMES` permission.
```js
// Apply the nickname "Bob the builder" to @Dude#0007 for 4 hours.
.forcenick @Dude#0007 4h Bob the builder
```

### `.mute <user:member> [reason:str...]`
Mutes the given member until `.unmute` is called or the role is removed manually.
Requires a mute role to be set. See [`.role mute`](cogs/moderation#role-mute-muteroleroledelete) to configure it.
Requires the `MANAGE_MESSAGES` permission.
```js
// Mute the given member.
.mute @Dude#0007

// Same as above, but provide a reason.
.mute @Dude#0007 spamming after prior warning
```

### `.tempmute <user:member> <duration:duration> [reason:str...]`
Temporarily mute the given member.
Bolt will unmute the member after `duration`, a manual unmute is possible using `.unmute`.
Requires a mute role to be set. See [`.role mute`](cogs/moderation#role-mute-muteroleroledelete) to configure it.
Requires the `MANAGE_MESSAGES` permission.
```js
// Mute the given member for a day.
.tempmute @Dude#0007 1d

// Same as above, but provide a reason.
.tempmute @Dude#0007 1d spamming after prior warning
```

### `.unmute <user:member...>`
Unmutes the given member, given that they are currently muted.
Requires the `MANAGE_MESSAGES` permission.
```js
// Unmute the given member.
.unmute @Dude#0007
```

### `.temprole <user:member> <role:role> <duration:duration> [reason:str...]`
Temporarily applies the given role to the given user. Bolt will remove the role after the given duration.
An infraction will be created and stored in the infraction database.
If the role is removed from the member manually while the temprole is active, Bolt will not attempt to automatically remove it. If this happens, Bolt logs it under *INFRACTION_UPDATE*.
Requires the `MANAGE_ROLES` permission.
```js
// Apply the given role to the given user for 2 hours.
.temprole @Guy Muted 2h

// Same as above, but use the member's ID instead of a direct mention.
.temprole 252908391075151874 Muted 2h

// Same as above, but provide a reason.
.temprole @Guy Muted 2h spamming #general with nonsense after prior warning
```

### `.kick <user:member> [reason:str...]`
Kicks the given member with an optional reason.
An infraction will be created and stored in the infraction database.
Requires the `KICK_MEMBERS` permission.
```js
// Kick the given user.
.kick @Guy

// Same as above, but provide a reason
.kick @Guy complaining about repeated punishments to write documentation
```

?> Changed in version [`0.3.2`](changelog#v031): Now respects role hierarchy restrictions.

### `.tempban <user:snowflake|member> <duration:duration> [reason:str...]`
Temporarily bans the given user with an optional reason. Bolt will remove the ban after the given duration.
An infraction will be created and stored in the infraction database.
If the user is not a member of the guild, it's possible to directly pass the ID as the `user` argument.
Requires the `BAN_MEMBERS` permission.
```js
// Temporarily ban the given user for 2 days.
.tempban @Guy 2d

// Same as above, but use the member's ID instead of a direct mention.
.tempban 252908391075151874 2d

// Same as above, but provide a reason.
.tempban @Guy 2d escalation from previous kick
```

?> Changed in version [`0.3.2`](changelog#v031): Now respects role hierarchy restrictions.

### `.ban <user:snowflake|member> [reason:str...]`
Bans the given user with an optional reason.
An infraction will be created and stored in the infraction database.
If the user is not a member of the guild, it's possible to directly pass the ID as the `user` argument.
Requires the `BAN_MEMBERS` permission.
```js
// Permanently ban the given user.
.ban @Guy

// Same as above, but use the member's ID instead of a direct mention.
.ban 252908391075151874

// Same as above, but provide a reason.
.ban @Guy repeated spamming after multiple warnings
```

?> Changed in version [`0.3.2`](changelog#v031): Now respects role hierarchy restrictions.

### `.clean`
Deletes a bunch of messages at once.
Due to limitations of the Discord API, this command cannot delete messages older than 2 weeks, and will ignore any that it finds in the command invocation.
`clean` is a special command that uses its own argument parser.
There are two ways to invoke `.clean`:
- `.clean <limit:int>`: deletes up to `limit` messages
- `.clean <options...>`: deletes messages matching options, see below

`clean` supports special options that you can specify:
* `--user <user:snowflake|user>`: delete only messages by `user`, can be specified multiple times
* `--channel <channel:textchannel>`: delete messages in `channel`, defaults to the current channel
* `--bots`: delete only bot messages
* `--no-bots`: don't delete any bot messages
* `--content <text:str>`: delete only messages containing `text`
* `--limit <limit:int>`: deletes up to `limit` messages, capped at 1000

```js
// Delete the last 80 messages
.clean 80

// Delete up to 100 messages sent by @Guy
.clean --user @Guy --limit 100

// Delete only bot messages in the past 100 messages
.clean --bots --limit 100

// Delete only messages containing '.clean' sent by non-bots in the past 40 messages
.clean --no-bots --content .clean --limit 40
```

### `.lastjoins`
Display the most recently joined members.

Similar to the `clean` command, the `lastjoins` command supports special options
for customizing the result:
* `--no-roles`: Display only new members without any roles
* `--roles`: Display only new members with any roles
* `--no-messages`: Display only new members that have not sent any messages
* `--messages`: Display only new members that have sent any messages
* `--total`: The total amount of members to display, defaults to 5, maximum is 15

```js
// display the 5 most recently joined members
.lastjoins

// display the 10 most recently joined members that have sent a message recently
.lastjoins --messages --total 10

// display the 15 most recently joined members without roles
.lastjoins --no-roles --total 15
```

?> Added in version [`v0.12.0`](changelog#v0120).

## Configuration commands
### `.role mute [muterole:role...|delete]`
Configures the role to be applied on usage of the `mute` and `tempmute` commands.
Note that these commands can be used by users with the `MANAGE_MESSAGES` permission instead of `MANAGE_ROLES` to account for the usecase of having a staff role which doesn't have the permission to manage roles.
Without any arguments, shows the currently configured mute role.
When invoked as `.role mute delete`, deletes the currently configured mute role.

```js
// Show the currently configured mute role
.role mute

// Set the mute role to the role called 'Muted'
.role mute Muted

// Delete the currently configured mute role
.role mute delete
```
