defmodule Bolt.Cogs.Hello do
  use Alchemy.Cogs

  Cogs.def echo(content) do
    Cogs.say "beep bop `#{content}`"
  end
end

