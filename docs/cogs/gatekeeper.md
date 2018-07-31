# Gatekeeper
Gatekeeper is Bolt's system which handles new members joining your guild.
It can be configured to send messages to users on either a guild channel or directly.
This cog lives under the command group `.gatekeeper`, but it's also possible to use it through the aliases `.keeper` or `.gk`.
For brevity, this document uses the `.keeper` alias.


## Commands
### `.keeper onjoin <action...>`
Sets an action to be executed when a user joins.
Multiple actions can be set at the same time, but only one action of each type may be set at a time.

**Valid actions**:
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

**Templates**:
Templates are text with special interpolations.
Basically, once a user joins, certain text in the template will be replaced, and the result will be sent.
The following tokens are available:
- `{mention}`: Mentions the given user. For example, `Welcome {mention}` would become `Welcome @Dude#0007` assuming the new user is named `Dude#0007`.
