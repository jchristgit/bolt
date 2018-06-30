# Documentation syntax
Bolt's built-in `help` command and this online documentation use various symbols and fancy names to describe how to use a command.
This page will explain what they mean and how to interpret them.

## Arguments
The documentation differentiates between two argument types:
- `<arg>` indicates a **required** argument. A command won't work without required arguments.
- `[arg]` indicates an **optional** argument. It can be used with a command, but it isn't necessary.

When you want to provide multiple words to a arguments, you need to surround them
with quotes (due to the way Bolt's command parser works). As an example, consider
a command `.echo <name:str> <greeting:str>`. If you were to use it as `.echo bob the builder hello`,
Bolt would interpret `bob` as the `name` and `the` as the `greeting`.
If you were to use `.echo "bob the builder" hello`, Bolt would interpret `bob the builder` as the `name`
and `hello` as the `greeting`.

There is one special case to this: If an argument ends with `...`, that means it will "consume the rest".
For example, consider `.echo <greeting:str...>`. If it was `.echo <greeting:str>`, `.echo hello world` would
just pass `hello` for `greeting` and ignore the rest. However, because it's `<greeting:str...>`, you can use
`.echo hello world` and `hello world` will be passed as the `greeting`. This is often used with moderation
commands that take reasons, such as [`.note`](cogs/infractions#note-ltusermembergt-ltnotestrgt).

## Types
When describing an argument, it will usually appear in the form `<name:type>`.
`name` is nothing too important, it's simply a name that should help you in understanding what
this command is used for. However, `type` describes what kind of argument Bolt expects.

Bolt understands the following types:
- `str`: Generic text. Pretty much anything. you can write.

- `int`: An [integer](https://en.wikipedia.org/wiki/Integer), for example `3` or `42`.

- `snowflake`: A Discord ID. Basically like `int`. You can obtain this from the `roleinfo`,
  `memberinfo`, and `guildinfo` commands, or by enabling developer mode and copying the ID manually.

- `member`: A member of your guild. Can be given as either a mention, the member's ID,
  a User#Discriminator combination, the username, or the nickname. For example: `@bolt`,
  `252908391075151874`, `bolt#5275` or `bolt`.

- `role`: A role on your guild. Can be given either by name, by mention or by ID
  For example: `Admin`, `@Admin` or `451824750399062036`.

- `channel`: A channel on your guild. Can be given either by name, by mention, or by ID.
  For example: `#stafflog`, `stafflog` or `451842566472859648`.

- `duration`: Text describing a duration. Bolt uses an internal parser for this kind of type.
  The following time units are supported:
  - `s`: seconds
  - `m`: minutes
  - `h`: hours
  - `d`: days
  - `w`: weeks

  When passing arguments of this type, use the form `<amount><unit>`. For example, to pass
  a duration spanning 5 days, use `5d`. You can also combined multiple units, for example `2h30m`.
