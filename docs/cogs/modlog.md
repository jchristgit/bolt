# Modlog
Bolt includes a modlog for logging events happening on your server.
A fine-grained configuration of which events get logged where is possible.
For example, one might want to log message edits and deletes in one channel, but moderator actions in another.

## Events
Events are dispatched to their configured mod logs.
Which log to dispatch to is configured via the `.modlog set` command, explained below.
Bolt knows the following events:

- `AUTOMOD`

  Emitted by automatic moderator actions caused by the bot.
  Self-assignable roles and USW actions will pop this event.

- `SELF_ASSIGNABLE_ROLES`

  Emitted when a member assigns or unassigns a role that was made
  self-assignable.

- `BOT_UPDATE`

  Emitted when the bot administrator performs an action on the bot
  that should be known by guilds using Bolt.

- `CONFIG_UPDATE`

  Emitted when someone changes the bot configuration for your guild.
  Adding or removing self-assignable roles, configuring the modlog, and
  other similar commands will pop this event.

- `INFRACTION_CREATE`

  Emitted when an infraction is created by a command.
  View [Moderation commands](cogs/moderation) and [Infraction commands](cogs/infractions)
  for more information.

- `INFRACTION_UPDATE`

  Emitted when an infraction is updated by a user or by Bolt.
  Updating the infraction reason or expiry will pop this event.
  Bolt will pop this event if he updates an infraction himself -
  for example, if an active temporary role is manually removed by a moderator
  and Bolt switches the infraction to inactive.

- `INFRACTION_EVENTS`

  Emitted by Bolt when an infraction causes him to perform an action.
  For example, the `temprole` command will cause Bolt to log when it
  removes the temporary role from a user (or if that fails for some reason).

- `MESSAGE_CLEAN`

  Emitted when a moderator (specifically, someone with the `MANAGE_MESSAGES` permission)
  invokes the [`clean`](cogs/moderation#clean) command. Includes a file with a log of the
  messages that were deleted.

- `CHANNEL_CREATE`

  Emitted when a new channel is created.

- `CHANNEL_UPDATE`

  Emitted when a channel is updated.

- `CHANNEL_DELETE`

  Emitted when a channel is deleted.

- `ERROR`

  Emitted when bolt attempts to perform an automatic action but encounters an error.

- `MESSAGE_EDIT`

  Emitted when a user edits a message. Bolt maintains an internal message
  cache and will attempt to fetch the original content of the message,
  but this is not always possible.

- `MESSAGE_DELETE`

  Emitted when a user deletes a message. As with `MESSAGE_EDIT`,
  Bolt maintains an internal message cache and will attempt to
  fetch the original content of the message, but this is not always possible.

- `GUILD_BAN_ADD`

  Emitted when a member is banned, either manually or through bolt.

- `GUILD_BAN_REMOVE`

  Emitted when a member is unbanned. In addition to the configurable logging,
  Bolt will check the infraction database for temporary or permanent bans
  and set these to inactive if applicable.

- `GUILD_MEMBER_ADD`

  Emitted when a user joins your guild.

- `GUILD_MEMBER_UPDATE`

  Emitted when a member is updated - for example, they got a new nick,
  added or removed a role, and others

- `GUILD_MEMBER_REMOVE`

  Emitted when a user leaves your guild.

- `GUILD_ROLE_CREATE`

  Emitted when a role is created.

- `GUILD_ROLE_UPDATE`

  Emitted when a role is updated - for example, it got a new colour,
  a new name, a new position or is now hoisted on the member list.

- `GUILD_ROLE_DELETE`

  Emitted when a role is deleted.

- `USER_UPDATE`

  Emitted when a user updates themselves. This is different from
  the `GUILD_MEMBER_UPDATE` because Discord differentiates between
  users and members. For example, a user updating their username or
  avatar will emit this event.

Bolt also includes built-in event explanations, available
with the `.modlog events` and `.modlog explain <event:str>` commands.

?> It is recommended to at least enable logging for `AUTOMOD`, `BOT_UPDATE`,
`CONFIG_UPDATE`, `ERROR`, `INFRACTION_CREATE`, `INFRACTION_EVENTS` and `INFRACTION_UPDATE`
to ensure the most important events are logged.


## Commands
### `.modlog status [unlogged]`
Shows the current configuration of the mod log - specifically, where which events are logged.
When invoked as `modlog status unlogged`, shows events that are not logged currently.
Requires the `MANAGE_MESSAGES` permission.
```js
// Show the current configuration of the mod log
.modlog status

// Show currently unlogged events
.modlog status unlogged
```

### `.modlog set <event:str> <channel:textchannel>`
Start logging the given `event` in the given `channel`.
When 'all' is given for `event`, logs all events in the given `channel`.
Requires the `MANAGE_GUILD` permission.
```js
// Start logging the `INFRACTION_CREATE` event in the #stafflog channel.
.modlog set INFRACTION_CREATE #stafflog

// Start logging all events in the #stafflog channel.
.modlog set all #stafflog
```

### `.modlog unset <event:str>`
Stop logging the given `event` in the currently configured channel.
When 'all' is given for `event`, stops logging all events.
Requires the `MANAGE_GUILD` permission.
```js
// Stop logging the `MESSAGE_DELETE` event in the #stafflog channel.
.modlog unset MESSAGE_DELETE

// Stop logging all events.
.modlog unset all
```

### `.modlog events`
Shows all events known to Bolt.
This can be useful in conjunction with the `.modlog explain` command documented below.
Requires the `MANAGE_GUILD` permission.
```js
// Show all known events.
.modlog events
```

### `.modlog explain <event:str>`
Built-in event reference. Explains the given `event`.
Requires the `MANAGE_GUILD` permission.
```js
// Explain the `AUTOMOD` event.
.modlog explain AUTOMOD
```
