defmodule Bolt.Cogs.Help do
  alias Bolt.Constants
  alias Bolt.Commander.Server
  alias Nostrum.Api
  alias Nostrum.Struct.Embed

  @prefix Application.fetch_env!(:bolt, :prefix)

  @spec format_command_detail(String.t(), String.t(), String.t()) :: Embed.t()
  defp format_command_detail(name, usage, description) do
    %Embed{
      title: "❔ `#{name}`",
      description: """
      ```ini
      #{
        usage
        |> Stream.map(&"#{@prefix}#{&1}")
        |> Enum.join("\n")
      }
      ```
      #{description}
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

  def command(msg, "") do
    embed = %Embed{
      title: "All commands",
      description:
        Server.all_commands()
        |> Map.keys()
        |> Stream.map(&"`#{@prefix}#{&1}`")
        |> Enum.join(", "),
      color: Constants.color_blue()
    }

    Api.create_message(msg.channel_id, embed: embed)
  end

  def command(msg, command_name) do
    embed =
      case Server.lookup(command_name) do
        nil ->
          format_command_not_found(command_name)

        %{help: help, usage: usage} ->
          format_command_detail(command_name, usage, help)
      end

    Api.create_message(msg.channel_id, embed: embed)
  end
end
