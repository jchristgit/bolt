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
