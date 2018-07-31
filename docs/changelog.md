# Changelog

## Unreleased
- add `modlog status unlogged` to view unlogged modlog events

## v0.10.2
- prevent duplicate `add role` join actions on a per-role basis
- prevent duplicate `send to` join actions on a per-channel basis
- prevent duplicate `send dm` join actions

## v0.10.1
- prevent duplicate `add role` / `remove role` accept actions on a per-role basis
- prevent duplicate `delete invocation` accept actions

## v0.10.0
- add the Gatekeeper cog
- add the `ERROR` modlog action

## v0.9.0
- infraction IDs of members with active infractions (only applies to temprole, tempmute, and mute)
  leaving are added to the leave log message
- added the `forcenick` command

## v0.8.0
- add the `GUILD_BAN_ADD` and `GUILD_BAN_REMOVE` modlog events
- show username and discrim in addition to mention in `inrole` command
- update to newest Elixir version
- renamed USW "filters" to "rules"

## v0.7.0
- add the `MENTIONS` filter
- `per` can now be optionally be written in `usw set`, for example `usw set 5 per 7`
- `usw set` and `usw unset` now emit modlog events with `CONFIG_UPDATE`
- update `usw set` response to better reflect what it's actually doing
- `usw` will now attempt to dm users on punishment
- role ordering will no longer mess up role update logging
- fix reversed clean log in `clean` command

## v0.6.0
- add the `LINKS` filter
- add the `NEWLINES` filter
- add the `inrole` command
- sort `usw status` fields by filter name

## v0.5.0
- a lot more readable and concise formatting in `infr user` and `infr list`

## v0.4.2
- fix `MESSAGE_DELETE` logs not displaying the message content
- improve message update formatting

## v0.4.1
- fix converters incorrectly picking up names such as `250k` as an ID

## v0.4.0
- added the `DUPLICATES` USW filter

## v0.3.2
- `kick` now respects role hierarchy restrictions
- `tempban` now respects role hierarchy restrictions
- `ban` now respects role hierarchy restrictions

## v0.3.1
- Fix `MESSAGE_UPDATE` event not being logged anymore
- Fix `MESSAGE_DELETE` event not being logged anymore

## v0.3.0
- Added the `tag raw` command
- Added the `tag info` command

## v0.2.0
- Initial release
