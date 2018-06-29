# Modlog commands
Bolt includes a modllog for logging events happening on your server.
A fine-grained configuration of which events get logged where is possible.
For example, one might want to log message edits and deletes in one channel, but moderator actions in another.

## Events
Events are dispatched to their configured mod logs.
Which log to dispatch to is configured via the `.modlog set` command, explained below.
Bolt knows the following events:
- `AUTOMOD`

  Emitted by automatic moderator actions caused by the bot.
  Self-assignable roles and USW actions will pop this event.

- `BOT_UPDATE`

  Emitted when the bot administrator performs an action on the bot
  that should be known by guilds using bolt.

- `CONFIG_UPDATE`

  Emitted when someone changes the bot configuration for your guild.
  Adding or removing self-assignable roles, configuring the modlog, and
  other similar commands will pop this event.

- `INFRACTION_CREATE`

  Emitted when an infraction is created by a command.
  View [Moderation commands](commands/moderation) and [Infraction commands](commands/infractions)
  for more information.

- `INFRACTION_UPDATE`

  Emitted when an infraction is updated by a user or by bolt.
  Updating the infraction reason or expiry will pop this event.
  Bolt will pop this event if he updates an infraction himself -
  for example, if an active temporary role is manually removed by a moderator
  and bolt switches the infraction to inactive.

- `INFRACTION_EVENTS`

  Emitted by bolt when an infraction causes him to perform an action.
  For example, the `temprole` command will cause bolt to log when it
  removes the temporary role from a user (or if that fails for some reason).

- `CHANNEL_CREATE`

  Emitted when a new channel is created.

- `CHANNEL_UPDATE`

  Emitted when a channel is updated.

- `CHANNEL_DELETE`

  Emitted when a channel is deleted.

- `MESSAGE_EDIT`

  Emitted when a user edits a message. Bolt maintains an internal message
  cache and will attempt to fetch the original content of the message,
  but this is not always possible.

- `MESSAGE_DELETE`

  Emitted when a user deletes a message. As with `MESSAGE_EDIT`,
  Bolt maintains an internal message cache and will attempt to
  fetch the original content of the message, but this is not always possible.

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
  the `GUILD_MEMBER_UPDATE` update because Discord differs between
  users and members. For example, a user updating their username or
  avatar will emit this event.

Bolt also includes built-in event explanations, available
with the `.modlog events` and `.modlog explain <event:str>` commands.


## Commands
### `.modlog status`
Shows the current configuration of the mod log (and where which events are logged).
Requires the `ADMINISTRATOR` permission.
```js
// Show the current configuration of the mod log
.modlog status
```

## `.modlog set <event:str> <channel:textchannel>`
Log the given `event` in the given `channel`.
When 'all' is given for `event`, logs all events in the given `channel`.
Requires the `ADMINISTRATOR` permission.
```js
// Log the `INFRACTION_CREATE` event in the #stafflog channel.
.modlog set INFRACTION_CREATE #stafflog

// Log all events in the #stafflog channel.
.modlog set all #stafflog
```

## `.modlog unset <event:str>`
Stop logging the given `event` in the currently configured channel.
When 'all' is given for `event`, stops logging all events.
Requires the `ADMINISTRATOR` permission.
```js
// Stop logging the `MESSAGE_DELETE` event in the #stafflog channel.
.modlog unset MESSAGE_DELETE

// Stop logging all events.
.modlog unset all
```

## `.modlog events`
Shows all events known to bolt.
This can be useful in conjunction with the `.modlog explain` command documented below.
Requires the `ADMINISTRATOR` permission.
```js
// Show all known events.
.modlog events
```

## `.modlog explain <event:str>`
Built-in event reference. Explains the given `event`.
Requires the `ADMINISTRATOR` permission.
```js
// Explain the `AUTOMOD` event.
.modlog explain AUTOMOD
```

## `.modlog mute`
Temporarily mutes the mod log.
This is NOT persistent across restarts of bolt.
Unset mod logging with `.modlog unset all` if you disable mod logging for a prolonged period of time.
Requires the `ADMINISTRATOR` permission.
```js
// Mute the mod log temporarily.
.modlog mute
```

## `.modlog unmute`
Unmute the mod log again, if it was previously muted through `.modlog mute`.
Requires the `ADMINISTRATOR` permission.
```js
// Unmute the mod log after it was muted previously.
.modlog unmute
```
