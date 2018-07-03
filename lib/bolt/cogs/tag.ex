defmodule Bolt.Cogs.Tag do
  @moduledoc false

  @behaviour Bolt.Command

  @impl true
  def usage,
    do: [
      "tag <name:str>",
      "tag create <name:str> <content:str...>",
      "tag delete <name:str...>",
      "tag list"
    ]

  @impl true
  def description,
    do: """
    There are two ways to use the `tag` command.
    For reading tags, simply use `tag <name:str>`, for example `tag music`.
    For managing tags, check out `help tag <subcommand>`, for example `help tag create`.
    Valid subcommands are listed above.
    """

  @impl true
  def predicates, do: [&Bolt.Commander.Checks.guild_only/1]

  @impl true
  def command(msg, args) do
    alias Bolt.Cogs.Tag.Read

    Read.command(msg, args)
  end
end
