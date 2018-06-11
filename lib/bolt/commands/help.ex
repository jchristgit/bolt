defmodule Bolt.Commands.Help do
  use Alchemy.Cogs
  alias Alchemy.Embed
  require Alchemy.Embed
  alias Bolt.Constants

  @spec command_information(String.t()) :: {Module.t(), arity(), String.t()}
  defp command_information(cmd_name) do
    case Cogs.all_commands()[cmd_name] do
      {module, arity, function_name, _parser} -> {module, arity, function_name}
      res -> res
    end
  end

  @spec command_doc_base(Module.t(), arity(), String.t()) ::
          {{String.t(), arity()}, integer(), atom(), list(), String.t()}
  def command_doc_base(module, _cmd_arity, cmd_name) do
    module
    |> Code.get_docs(:docs)
    |> Enum.find(fn {{name, _arity}, _, _, _args, _doc} -> cmd_name == name end)
  end

  @spec format_args(list()) :: String.t()
  defp format_args(args) do
    args
    |> Stream.drop(1)
    |> Stream.map(fn val ->
      case val do
        {_, _, [{arg_name, _, _}, default]} -> "<#{arg_name}[=#{default}]>"
        {arg_name, _, _} -> "<#{arg_name}>"
        val -> "#{inspect(val)}"
      end
    end)
    |> Enum.join(" ")
  end

  @spec command_overview() :: Enumerable.t()
  defp command_overview do
    Cogs.all_commands()
    |> Map.values()
    |> Stream.map(fn cmd_info ->
      {module, arity, function_name} =
        case cmd_info do
          {module, arity, function_name} -> {module, arity, function_name}
          {module, arity, function_name, _parser} -> {module, arity, function_name}
        end

      command_doc_base(module, arity, function_name)
      |> (fn {{name, _arity}, _, _, args, doc} ->
            formatted_args = format_args(args)
            arg_string = if formatted_args != "", do: " `#{formatted_args}`", else: ""

            if doc == nil do
              "**`#{name}`**#{arg_string}"
            else
              "**`#{name}`**#{arg_string}\n#{hd(String.split(doc, "\n"))}"
            end
          end).()
    end)
    |> Enum.join("\n\n")
  end

  @spec format_command_overview() :: Embed.t()
  def format_command_overview do
    %Embed{
      title: "command overview",
      description: command_overview(),
      color: Constants.color_blue()
    }
    |> Embed.footer(
      text:
        "use `#{Application.fetch_env!(:bolt, :default_prefix)}help <command>` for more details"
    )
  end

  @spec format_command_detail(Module.t(), arity(), String.t()) :: String.t() | nil
  defp format_command_detail(module, cmd_arity, cmd_name) do
    {{name, arity}, _, _, args, doc} = command_doc_base(module, cmd_arity, cmd_name)

    %Embed{
      title: "❔ `#{name}/#{arity - 1}`",
      description: """
      ```ini
      #{name} #{format_args(args)}
      ```
      #{if is_bitstring(doc), do: doc, else: "Seems like I didn't write any docs for this yet..."}
      """,
      color: Constants.color_blue()
    }
  end

  @spec format_command_not_found(String.t()) :: Embed.t()
  defp format_command_not_found(command_name) do
    %Embed{
      title: "Command not found: `#{command_name}`",
      description: "Hmmm.. I looked everywhere, but couldn't find that command.",
      color: Constants.color_red()
    }
  end

  @doc """
  View all available commands.

  If you want to view more detailed help for a single
  command, use `#{Application.get_env(:bolt, :prefix)}help command` - for example, to show
  what you're reading currently, use `#{Application.get_env(:bolt, :prefix)}help help`.
  """
  Cogs.def help do
    format_command_overview()
    |> Embed.send()
  end

  @doc """
  View detailed help for the given command.
  """
  Cogs.def help(command_name) do
    command_name = String.downcase(command_name)

    case command_information(command_name) do
      {module, arity, function_name} ->
        format_command_detail(module, arity, function_name)
        |> Embed.send()

      nil ->
        format_command_not_found(command_name)
        |> Embed.send()
    end
  end
end
