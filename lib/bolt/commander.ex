defmodule Bolt.Commander do
  alias Bolt.Cogs
  alias Bolt.Commander.Parsers

  @commands %{
    "echo" => %{
      callback: &Cogs.Echo.command/3,
      parser: &OptionParser.split/1,
      help: "Echo the given command."
    },
    "guildinfo" => %{
      callback: &Cogs.GuildInfo.command/3,
      parser: &Parsers.passthrough/1,
      help: "Show information about the current Guild."
    },
    "memberinfo" => %{
      callback: &Cogs.MemberInfo.command/3,
      parser: &Parsers.passthrough/1,
      help: "Show information about the mentioned member, or yourself."
    },
    "roleinfo" => %{
      callback: &Cogs.RoleInfo.command/3,
      parser: &Parsers.passthrough/1,
      help: "Show information about the given role."
    }
  }

  @aliases %{
    "ginfo" => "guildinfo",
    "guild" => "guildinfo",
    "minfo" => "memberinfo",
    "member" => "memberinfo",
    "rinfo" => "roleinfo",
    "role" => "roleinfo"
  }

  @doc """
  Handle a message sent over the gateway.
  If the message starts with the prefix and
  contains a valid command, the arguments
  are parsed accordingly and passed to
  the command along with the message.
  Otherwise, the message is ignored.
  """
  @spec handle_message(Nostrum.Struct.Message.t()) :: no_return
  def handle_message(msg) do
    case String.split(msg.content) do
      ["." <> command_name | args] ->
        case Map.get(@commands, command_name) do
          nil ->
            case Map.get(@aliases, command_name) do
              nil ->
                :ignored

              command_alias ->
                %{callback: callback, parser: parser} = Map.get(@commands, command_alias)
                callback.(command_name, msg, parser.(Enum.join(args, " ")))
            end

          %{callback: callback, parser: parser} ->
            # TODO: Instead of splitting the entire message content,
            #       only split off the actual command, since that is
            #       not of interest to the command handler.
            callback.(command_name, msg, parser.(Enum.join(args, " ")))
        end

      _ ->
        :ignored
    end
  end
end
