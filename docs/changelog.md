# Changelog

## Unreleased
- update to newest Elixir version.

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
