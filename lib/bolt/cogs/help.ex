defmodule Bolt.Cogs.Help do
  @moduledoc false

  alias Bolt.Commander.Server
  alias Bolt.Constants
  alias Nostrum.Api
  alias Nostrum.Struct.Embed

  @prefix Application.fetch_env!(:bolt, :prefix)

  @spec format_command_detail(String.t(), [String.t()], String.t()) :: Embed.t()
  def format_command_detail(name, usage, description) do
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
    case Server.lookup(command_name) do
      nil ->
        response = "🚫 unknown command"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)

      %{help: help, usage: usage} ->
        embed = format_command_detail(command_name, usage, help)
        Api.create_message(msg.channel_id, embed: embed)
    end
  end
end
