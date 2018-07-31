# Meta
Meta commands are not strictly necessary, but they often prove useful. For example, you might want to find out when a user joined, or view general statistics for your guild.


## Commands
### `.guildinfo [guild:snowflake]`
Provides general information about the guild the command is used on.
If you have a specific guild ID you want to look up, you can pass it as an argument.
You can obtain a guild ID to look up from this command, or by right-clicking a guild in your server list and clicking *Copy ID*. This requires Developer Mode to be enabled.
Aliased to `.ginfo` and `.guild`.
```js
// Look up information for the current guild.
.guildinfo

// Look up information for the guild with the given ID.
.guildinfo 451824027976073216
```

### `.roleinfo <role:role...>`
Shows information about the given role.
Aliased to `.rinfo` and `.role`.
```js
// Show information for the role named 'Admin'.
.roleinfo Admin

// The `role` argument is case-insensitive, so the following will work the same way:
.roleinfo admin

// Show information by role ID.
.roleinfo 451824750399062036

// Show information by role mention.
.roleinfo @Admin
```

### `.memberinfo [member:member...]`
Shows information about the given member. When no member is given, shows information about yourself.
Aliased to `.minfo` and `.member`.
```js
// Show information about yourself.
.memberinfo

// Show information about the member bolt#5275.
.memberinfo bolt#5275

// Same as above, but mention the member directly.
.memberinfo @bolt

// Same as above, but pass the member's ID.
.memberinfo 252908391075151874

// Same as above, but pass the member's username.
.memberinfo bolt
```

## `.inrole <role:role...>`
Shows all members with the given role.
```js
// Show members in the 'Muted' role.
.inrole muted
```

?> Changed in version [`0.8.0`](changelog#v080): Now shows username and discriminator in addition to the mention.

## `.roles [options...]`
Shows all roles on the server.
The following options can be given to customize the output:
- `--compact`: Separate roles by commas and omit the role ID
- `--no-mention`: Display the role names instead of displaying the role mention
- `--sort-by color|members|name|position`: Specify the sorting order of the roles, defaults to `name`
- `--reverse|--no-reverse`: Reverse the sorting order - when `sort-by` is given as either *members*, *name* or *position*, `--reverse` is implied for sanity reasons, use `--no-reverse` to sort regularly
```js
// Show all roles on the server, sorted by name.
.roles

// Show all roles on the server, sorted by name, but order from Z to A instead of A to Z.
.roles --no-reverse

// Show all roles on the server, sorted by position.
.roles --sort-by position

// Show all roles on the server sorted by member count in compact format.
.roles --compact --sort-by members

// Show all roles in compact format, but display the role name instead of the role mention.
.roles --no-mention
```

### `.help [command:str]`
Shows help for the given command or command group. When no command or command group is given, shows all available commands.
`syntax` is special: It's not a regular command, and it's only accessible through the `.help` command. When you run `.help syntax`, Bolt will explain how to interpret command help.
Aliased to `.man`.
```js
// Show all available commands.
.help

// Show help for the given command or command group.
.help tempban

// Show the explanation for the way command help is written.
.help syntax
```

### `.guide`
A paginated overview that guides you through setting up Bolt on your server.
Keep in mind that paginated embeds automatically expire after 15 minutes. Feel free to re-run the command if it expires and you're still reading.
```js
// Show bolt's built-in guide.
.guide
```

### `.stats`
Shows general statistics over the bot - for example, in how many guilds he is, how many members he sees, and potentially some more interesting information.
```js
// Show bot statistics.
.stats
```
