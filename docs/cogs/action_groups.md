# Action groups

Bolt's action group subsystem was built to create a reusable way of configuring
actions to take on various events, such as the USW subsystem or raid management.
They can also be triggered manually.

At its core, an *action group* is a collection of actions, such as "delete
invite links". Action groups are managed via the `.ag` (short for
`.actiongroup`) command group.

?> Added in version [`v0.12.0`](changelog#v0120).


## Deduplication

By default, any action group run is *deduplicated*. This means that if an action
group were to be executed twice at the same time, the second run of the group is
dropped silently. Most of the time, this is what you want, since it prevents
bolt from running action groups twice due to lag with the Discord API and other
timing differences. The USW subsystem uses the same deduplication logic.


## Commands

### `.ag add <group:str> <action:str> [args...]`

Add the given action for the named action group. The action group must have been
created previously via the `.ag create <name:str>` command.
See the help output for the command for information on which actions can be
performed.
Requires the `MANAGE_GUILD` permission.

```js
// Make the "raidgroup" action group delete the vanity URL
.ag add raidgroup delete_vanity_url
```

### `.ag clear <group:str>`

Clear all actions for the named action group.
If you want to reconfigure the actions that are part of the group, you probably
want to use this instead of the `.ag delete` command, as the delete command
will also remove the action group from any configuration it was used in
previously.
Requires the `MANAGE_GUILD` permission.

```js
// Clear all actions in "raidgroup"
.ag clear raidgroup
```

### `.ag create <name:str>`

Create a new action group with the given `name`.
Requires the `MANAGE_GUILD` permission.

```js
// Create an empty action group named "raidgroup"
.ag create raidgroup
```

### `.ag delete <group:str>`

Delete the given action group and all of its actions.
Any link made from another system to the given action group will also be
removed. If you simply want to clear the actions run as part of an action group,
use the `.ag clear` command instead.
Requires the `MANAGE_GUILD` permission.

```js
// Delete the action group "raidgroup" and all of its actions
// as well as all references to it from other modules
.ag delete raidgroup
```

### `.ag list`

List all action groups that are configured for the guild.
Requires the `MANAGE_GUILD` permission.

```js
// Show all action groups on the guild
.ag list
```

### `.ag show <group:str>`

Shows the configured actions in the given group.
Requires the `MANAGE_GUILD` permission.

```js
// Show the actions that are run as part of the "raidgroup" group
.ag show raidgroup
```

### `.ag trigger <group:str>`

Manually trigger an invocation of the given action group.
This is very useful in cases where you want to test the functionality of an
action group, for instance if you have linked an action group to another
subsystem that may be hard to trigger yourself.
Requires the `MANAGE_GUILD` permission.

```js
// Trigger the "raidgroup" action group manually.
.ag trigger raidgroup
```
