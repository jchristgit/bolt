defmodule Bolt.Commands.Hello do
  use Alchemy.Cogs

  @doc """
  Greet the user specified with `name` with the given `content`.
  """
  Cogs.def echo(content, name \\ "bob") do
    name = String.trim_leading(name, "@")
    Cogs.say("#{content}, #{name}!")
  end
end
