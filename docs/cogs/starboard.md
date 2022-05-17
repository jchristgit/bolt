# Starboard

Bolt includes a configurable starboard that you can use to highlight special
messages in your community.

## Commands
### `.starboard configure <channel:textchannel> [min_stars=5]`
Enable the starboard in the given channel. If a mesasge has at least `min_stars`
`:star:` reactions, the bot copies the message into the starboard channel.
Requires the `MANAGE_MESSAGES` permission.

```js
// Enable the starboard in #starboard for five minimum stars
.starboard configure #starboard

// Enable the starboard in #starboard for ten minimum stars
.starboard configure #starboard 10
```

bolt's starboard is automatically disabled if the starboard channel is deleted.


<!-- vim: set textwidth=80 sw=2 ts=2: -->
