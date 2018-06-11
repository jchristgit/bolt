defmodule Bolt.Cogs.Help do
  use Alchemy.Cogs
  alias Alchemy.Embed
  require Alchemy.Embed
  alias Bolt.Constants

  defp get_command_information(command_name) do
    case Cogs.all_commands()[command_name] do
      {module, arity, function_name, parser} -> {module, arity, function_name}
      res -> res
    end
  end

  @spec format_command_help(Module.t(), integer(), String.t()) :: Embed.t()
  defp format_command_help(module, arity, function_name) do
    %Embed{
      title: "`#{function_name}`",
      description: "Maybe I could provide documentation here.",
      color: Constants.color_blue
    }
  end

  @spec format_command_not_found(String.t()) :: Embed.t()
  defp format_command_not_found(command_name) do
    %Embed{
      title: "Command not found: `#{command_name}`",
      description: "Hmmm.. I looked everywhere, but couldn't that command.",
      color: Constants.color_red
    }
  end

  Cogs.set_parser(:help, fn args -> args |> String.downcase |> List.wrap end)
  Cogs.def help(command_name) do
    case get_command_information(command_name) do
      {module, arity, function_name} ->
        format_command_help(module, arity, function_name)
        |> Embed.send

      nil ->
        format_command_not_found(command_name)
        |> Embed.send
    end
  end
end
