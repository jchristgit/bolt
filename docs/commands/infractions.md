# Infraction commands
Bolt tracks punishment applied to users through the infraction database. This page documents the commands used to interact with it.
The infraction commands listed here are all named with the `infr` command group, which is an alias for `infraction`.

## Infraction Types
Bolt supports the following infraction types:
- `note`
- `tempmute`
- `mute`
- `unmute`
- `temprole`
- `warning`
- `kick`
- `softban`
- `tempban`
- `ban`
- `unban`
These are not created directly, instead, they are created by bolt automatically through the moderation commands.


## `.note <user:member> <note:str...>`
Creates a note for the given user. The note is stored in the infraction database.
This can be useful for adding information to a user that is of interest for your staff team.
Requires the `MANAGE_MESSAGES` permission.
```js
// Create a note for the given user.
.note @Guy2 possible alt of @Guy

// Same as above, but using the member's ID.
.note 252908391075151874 possible alt of @Guy
```

## `.infr detail <id:int>`
View the given infraction ID in detail. The ID can be retrieved from the `infr list` or `infr user` commands, documented below.
Requires the `MANAGE_MESSAGES` permission.
```js
// View infraction ID `3` in detail.
.infr detail 3
```

## `.infr list [type:str]`
Lists all infractions on this guild When given a type out of the types listed above, shows only infractions with the given types.
Requires the `MANAGE_MESSAGES` permission.
```js
// Show all infractions on this guild.
.infr list

// Show only temporary bans.
.infr list tempban
```

## `.infr user <user:snowflake|member>`
Lists all infractions for the given user. It is possible to pass an ID directly to look up infractions for a member that left the guild.
Requires the `MANAGE_MESSAGES` permission.
```js
// Look up all infractions for the mentioned user.
.infr user @Guy

// Same as above, but by using the member's ID.
.infr user 252908391075151874
```

## `.infr reason <id:int> <new_reason:str...>`
Updates the reason for the given infraction ID. Useful when you did not add a reason when the infraction was created, or for fixing those pesky typos.
Only the infraction creator can update the reason for an infraction.
Additionally, requires the `MANAGE_MESSAGES` permission.
```js
// Update the reason for infraction #3
.infr reason 30 spamming #general
```

## `.infr expiry <id:int> <new_expiry:duration>`
Updates the infraction expiry. The new expiry is interpreted relative to the infraction creation.
Only applicable to timed (temporary) infractions that have not expired yet.
Requires the `MANAGE_MESSAGES` permission.
```js
// Change the expiry for infraction #35 to 2 days after creation.
.infr expiry 35 2d
```
