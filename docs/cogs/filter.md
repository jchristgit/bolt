# Filter
Bolt includes the ability to filter messages containing certain tokens (character sequences).
It can act to matching messages in a number of ways, for example, Bolt can just delete the message containing the tokens or even mute the user.
The actions to take on token match are configurable by server administrators.

## Commands
### `.filter show`
Shows the currently filtered tokens.
Requires the `MANAGE_GUILD` permission.
```js
// Show all filtered tokens on this server.
.filter show
```

### `.filter add <token:str...>`
Add a new token to the guild-wide filter.
Note that without a configured action, a filter being hit won't do anything.
Check out the `filter action` command to see how to configure actions.
Tokens must be unique (you can't filter one token multiple times).
Requires the `MANAGE_GUILD` permission.
```js
// Filter out messages containing the base invite
.filter add discord.gg

// Filter out messages containing "redis is a database"
.filter add redis is a database
```

### `.filter remove <token:str...>`
Removes the given token from the guild-wide filter.
Requires the `MANAGE_GUILD` permission.
```js
// Remove the filter for `discord.gg`.
.filter remove discord.gg
```
