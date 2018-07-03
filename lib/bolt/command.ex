defmodule Bolt.Command do
  @moduledoc "The command behaviour. Must be implemented by commands."

  alias Nostrum.Struct.Message

  @doc "Returns a list of possible ways to use the command (or its subcommands)."
  @callback usage() :: [String.t()]

  @doc "Returns a string describing what the command is and how it works."
  @callback description() :: String.t()

  @doc """
  Returns a list of predicates (see `Bolt.Commander.Checks`) that must
  pass before this module can be used.
  """
  @callback predicates() :: [(Message.t() -> {:ok, Message.t()} | {:error, String.t()})]

  @doc """
  An optional callback that can be used to parse the arguments into something
  more usable. For example, one might want to use `OptionParser` along with the
  arguments to create a more customized command.
  This command receives the command arguments with the prefix, command, and
  (if applicable) subcommand name removed, and should return whatever the
  `command/2` function should be passed as the `args` argument.
  """
  @callback parse_args(args :: [String.t()]) :: any()

  @doc """
  Actually execute the command invoked by the given `Message.t()`.
  The second parameter is a list of arguments with the command
  (or subcommand) along with the bot prefix removed.
  If the command defines `parse_args/1`, the returned value of
  that function will be passed instead (marked as `any()` here).
  The return value of this function is unused.
  """
  @callback command(msg :: Message.t(), args :: [String.t()] | any()) :: any()

  @optional_callbacks [parse_args: 1, predicates: 0]
end
