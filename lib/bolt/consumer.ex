defmodule Bolt.Consumer do
  use Nostrum.Consumer
  alias Bolt.Cogs

  @handlers %{
    MESSAGE_CREATE: [
      Cogs.Echo,
      Cogs.Help
    ]
  }

  def start_link() do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, {msg}, _ws_state}) do
    case msg.content do
      "." <> command_name ->
        if !msg.author.bot do
          [command_name | args] = msg.content |> OptionParser.split()

          @handlers[:MESSAGE_CREATE]
          |> Enum.each(& &1.command(command_name, msg, args))
        end

      _ ->
        :ignored
    end
  end

  def handle_event(_event) do
    :noop
  end
end
