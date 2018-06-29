# Self-assignable roles
Larger guilds often have a bunch of roles that members should be able to assign themselves. Self-assignable roles take the work off moderators and allow members to assign those roles directly through bolt.


## Commands
### `.assign <role:role...>`
Assigns the given self-assignable role from the message author.
Aliased to `.iam`.
```js
// Assign the role called 'Blue'.
.assign Blue

// Same as above, but using the alias.
.iam Blue
```

### `.remove <role:role...>`
Removes the given self-assignable role from the message author.
Aliased to `.iamn`.
```js
// Remove the role called 'Blue'.
.remove Blue

// Same as above, but using the alias.
.iamn Blue
```

### `.lsar`
Lists all self-assignable roles in a paginated embed.
```js
// Show all self-assignable roles on this guild.
.lsar
```

### `.role allow <role:role...>`
Adds the given role to the self-assignable roles.
Requires the `MANAGE_ROLES` permission.
```js
// Allow members to self-assign the role called 'Blue'.
.role allow Blue

// Same as above, but by using the role ID.
.role allow 451824750399062036
```

### `.role deny <role:role...>`
Removes the given role from the self-assignable roles.
Requires the `MANAGE_ROLES` permission.
```js
// Remove 'Blue' from the self-assignable roles.
.role deny Blue

// Same as above but by ID.
.role deny 451824750399062036
```
