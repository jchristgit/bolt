# Gatekeeper
Gatekeeper is Bolt's system which handles new members joining your guild.
Additionally, it handles the `.accept` command used for member verification.
With the exception of `.accept`, this cog lives under the command group `.gatekeeper`, but it's also possible to use it through the aliases `.keeper` or `.gk`.
For brevity, this document uses the `.keeper` alias.


## Commands
### `.accept`
Run by members to verify that they have read the rules and further information that the server requires them to.

### `.keeper actions [accept|join]`
Show configured actions. When `accept` or `join` are given, only shows accept
or join actions on their own.

```js
// Show all configured actions.
.keeper actions

// Show only configured accept actions.
.keeper actions accept
```

?> Added in version `0.12.0`.


### `.keeper onaccept <action...>`
Sets actions to be executed when a member runs `.accept`.

**Valid actions**:
- `add role <role:role...>`

  Adds the given `role` to members runnin `.accept`.
  If the member already has the role, nothing happens.
  Other errors are logged to the mod log with the event `ERROR`.

- `remove role <role:role...>`

  Removes the given `role` from members running `.accept`.
  If the member does not have the role, nothing happens.
  Other errors are logged to the mod log with the event `ERROR`.

- `delete invocation`

  Deletes the message running the command.

- `ignore`

  Deletes all existing actions that are set to run on `.accept`.

```js
// On `.accept`, remove the role 'Guest' from the member
.keeper onaccept remove role Guest

// On `.accept`, add the role 'Member' to the member
.keeper onaccept add role Member

// Remove all actions set to run on `.accept`.
.keeper onaccept ignore
```


### `.keeper onjoin <action...>`
Sets an action to be executed when a user joins.
Multiple actions can be set at the same time, but only one action of each type may be set at a time.

**Valid actions**:
- `add role <role:role...>`

  Adds the given `role` to the member who joined.
  In case this fails, it will log to mod log with the event `ERROR`.

- `ignore`

  Deletes all current actions executed on join.
  Using it is as simple as running `.keeper onjoin ignore`.

- `send <template:str> to user`

  Attempts to send the given template to the user who joined.
  If the user has DMs disabled, this won't do anything.
  See the section below on templates.
  For example, to (attempt to) send "Welcome to our server" to users joining the server in a direct message, you would use `.keeper send "Welcome to our server" to user`.

- `send <template:str> to <channel:textchannel>`

  Sends the given template to the given channel.
  See the section below on templates.
  For example, to send "Welcome to our server, @user-who-joined" in the *#welcome* channel, you would use `.keeper send "Welcome to our server, {mention}" to #welcome`.
  In case this fails, it will log to mod log with the event `ERROR`.
  Note that if you want to use this for logging, you're looking in the wrong place.
  Use the [Modlog functionality](cogs/modlog) for that.

**Templates**:
Templates are text with special interpolations.
Basically, once a user joins, certain text in the template will be replaced, and the result will be sent.
The following tokens are available:
- `{mention}`: Mentions the given user. For example, `Welcome {mention}` would become `Welcome @Dude#0007` assuming the new user is named `Dude#0007`.

```js
// On join, (attempt to) send "Welcome to our server!" to the user who joined
.keeper onjoin send "Welcome to our server!" to user

// On join, send "Welcome to our server, {mention}!" to the #welcome channel
.keeper onjoin send "Welcome to our server, {mention}!" to #welcome

// On join, add the role 'Guest' to the user who joined
.keeper onjoin add role Guest

// Delete all actions that were set to apply on member join.
.keeper onjoin ignore
```
