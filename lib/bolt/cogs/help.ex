defmodule Bolt.Cogs.Help do
  alias Bolt.Cogs
  alias Bolt.Constants
  alias Nostrum.Api
  alias Nostrum.Struct.Embed

  @cogs [
    Cogs.Echo,
    Cogs.Help
  ]

  @spec all_commands() :: [{{atom(), arity()}, integer(), atom(), list(), String.t()}]
  def all_commands() do
    @cogs
    |> Enum.map(fn cog ->
      cog
      |> IO.inspect(label: "cog")
      |> Code.get_docs(:docs)
      |> Enum.filter(fn cmd ->
        IO.inspect(cmd, label: "cmd")

        case cmd do
          {{:command, 3}, _, :def, args, _} -> is_bitstring(hd(args))
          _ -> false
        end
      end)
    end)
    |> List.flatten()
  end

  @spec find_commands_matching(String.t(), arity()) :: [
          {{atom(), arity()}, integer(), atom(), list(), String.t()}
        ]
  def find_commands_matching(cmd_name, _cmd_arity) do
    all_commands()
    |> Enum.filter(fn cmd ->
      case cmd do
        {{:command, 3}, _, :def, args, _doc} ->
          true

        _ ->
          false
      end
    end)
    |> IO.inspect()
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
    %{}
    |> Map.values()
    |> Stream.map(fn cmd_info ->
      {_module, arity, function_name} =
        case cmd_info do
          {module, arity, function_name} -> {module, arity, function_name}
          {module, arity, function_name, _parser} -> {module, arity, function_name}
        end

      find_commands_matching(function_name, arity)
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
    |> Embed.put_footer(
      "use `#{Application.fetch_env!(:bolt, :default_prefix)}help <command>` for more details",
      nil
    )
  end

  @spec format_command_detail({{String.t(), arity()}, integer(), atom(), list(), String.t()}) ::
          String.t() | nil
  defp format_command_detail({{name, arity}, _, _, args, doc}) do
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
  def command("help", msg, []) do
    embed = format_command_overview()
    Api.create_message(msg.channel_id, embed: embed)
  end

  @doc """
  View detailed help for the given command.
  """
  def command("help", msg, [command_name]) do
    command_name = String.downcase(command_name)

    embed =
      case find_commands_matching(command_name, nil) do
        [cmd_info | _others] ->
          format_command_detail(cmd_info)

        [] ->
          format_command_not_found(command_name)
      end

    Api.create_message(msg.channel_id, embed: embed)
  end
end
