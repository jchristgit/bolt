# Automod
Bolt includes automod functionality named Uncomplicated Spam Wall (USW).
When configured properly, this can take a lot of work of moderators. This page describes how to do so.

USW functions by applying *filters* on messages sent by users.
When a message comes in, Bolt checks for configured filters and applies all of them on the message.
If the message hits one of the limits that were configured on your guild, Bolt will apply the configured punishment.
Punishment escalation can be enabled to increase the punishment duration on repeated offenders.
Bolt will also attempt to DM the user and inform them about why they were given the role.

!> Be very careful when configuring filters.
An overly strict configuration *will* punish innocent members.


## Filters
- `BURST`

  The `BURST` filter checks repeated messages by the same user.
  For example, configuration set with `.usw set BURST 5 10` will allow
  *5* messages sent by the same user within *10* seconds before applying
  the configured punishment.

- `DUPLICATES`

  The `DUPLICATES` filter checks for messages with equal content
  sent by multiple users. For example, configuration set with
  `.usw set DUPLICATES 5 20` will allow *5* duplicated messages sent
  within *20* seconds. Punishment will apply on any user who
  sent at least a single duplicated message.

- `LINKS`

  The `LINKS` filter checks for the total amount of links in messages
  sent by a single user. For example, configuration set with
  `.usw set LINKS 4 10` will allow *4* links sent within *10* seconds.

- `NEWLINES`

  The `NEWLINES` filter checks for total amount of newlines in messages
  sent by a single user. For example, configuration set with
  `.usw set NEWLINES 20 10` will allow *20* newlines sent within *10* seconds.


## Punishments
- `temprole <role:role> <duration:duration>`

  Like the `.temprole` command, temporarily applies the given role to the offender
  and removes it after `duration`. Creates an infraction in the infraction database.
  For example, to apply a role called 'Muted' for 15 minutes, use `.usw punish temprole Muted 15m`.


## Automatic punishment escalation
Bolt includes the ability to automatically escalate punishment on repeated offenders.
When enabled, Bolt tracks recently punished users and will add the configured punishment duration
on top of the last punishment's duration on the next offense. In a nutshell, the formula used
for calculating punishment expiry is `duration + duration * escalation_level`, where `duration`
is the configured punishment duration and `escalation_level` is the current escalation level
of the user (starting from `0`).


## Commands
### `.usw status`
Shows the current status of the spam wall, including the current configuration,
whether automatic punishment escalation is enabled,
which filters are configured and at which rates.
Requires the `MANAGE_GUILD` permission.
```js
// Show the current USW configuration.
.usw status
```


### `.usw set <filter:str> <count:int> [per] <interval:int>`
Activate the given `filter` to allow `count` objects to pass through during `interval` seconds.
For more information on filters, see [Filters](#filters).
Requires the `MANAGE_GUILD` permission.
```js
// Activate the `BURST` filter to allow 5 messages during 10 seconds.
.usw set BURST 5 10

// Activate the `DUPLICATES` filter to allow 4 duplicated messages during 20 seconds.
.usw set DUPLICATES 4 20

// Same as above, but use `per` for readability.
.usw set DUPLICATES 4 per 20
```

?> Changed in version [`0.7.0`](docs/changelog#v060): Now allows `per` between `count` and `interval`.

?> Changed in version [`0.7.0`](docs/changelog#v070): Now logs to the modlog with `CONFIG_UPDATE`.


### `.usw unset <filter:str>`
Deactivate the given `filter` (case-insensitive).
Requires the `MANAGE_GUILD` permission.
```js
// Disable the `BURST` filter.
.usw unset BURST
```

?> Changed in version [`0.7.0`](docs/changelog#v070): Now logs to the modlog with `CONFIG_UPDATE`.


### `.usw punish <punishment...>`
Configures the punishment applied when a message hits one of the configured filters.
See [Punishments](#punishments) for details.
Requires the `MANAGE_GUILD` permission.
```js
// Punish offenders with the temporary role 'Muted' for 10 minutes.
.usw punish temprole Muted 10m
```


### `.usw escalate [on|off]`
Enable or disable automatic punishment escalation.
When not given any arguments, shows whether automatic punishment escalation is currently enabled.
See [Automatic punishment escalation](#automatic-punishment-escalation) for more details.
Requires the `MANAGE_GUILD` permission.
```js
// Show whether automatic punishment escalation is currently enabled.
.usw escalate

// Enable it.
.usw escalate on

// Disable it.
.usw escalate off
```
